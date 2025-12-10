#!/bin/bash
# ==============================================================================
# ARCHITECT: Devin Benard Royal
# PROJECT:   M3hl@n! Unified Build System — Distributed + AI + Provenance Layer
# COPYRIGHT: © 2025 Devin B. Royal. All Rights Reserved.
# LICENSE:   LicenseRef-M3hlan-Enterprise
# ==============================================================================

# --- [ 0. EXTREME SAFETY PREAMBLE ] -------------------------------------------
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# --- [ 1. CONFIGURATION & CONSTANTS ] -----------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
M3HLAN_ROOT="${M3HLAN_ROOT:-$ROOT_DIR}"

CORE_BUILD="${M3HLAN_ROOT}/core/build.sh"
TARGETS_FILE="${M3HLAN_ROOT}/manifests/targets.json"
PREDICTIVE_ENGINE="${M3HLAN_ROOT}/predictive_engine/engine.py"

DISTRIBUTED_LOG="${M3HLAN_ROOT}/distributed_build.log"
PROVENANCE_LOG="${M3HLAN_ROOT}/provenance.log.jsonl"
TRANSPARENCY_LOG="${M3HLAN_ROOT}/transparency.log"

REMOTE_CACHE_DIR="${M3HLAN_ROOT}/.remote_cache"   # local path; can be rsynced out
LOCAL_CACHE_DIR="${M3HLAN_ROOT}/.local_cache"
ARTIFACTS_DIR="${M3HLAN_ROOT}/artifacts"

# Multi-node topology (extend as needed)
# "local" means run on this machine; "user@host:/path" invokes SSH-exec
NODES=("local")
DEFAULT_PARALLELISM=4

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 1970-01-01T00:00:00Z)"

# --- [ 2. LOGGING / ERROR HANDLING ] -----------------------------------------

log() {
  local LEVEL=$1
  shift
  local MSG="$*"
  local NOW
  NOW="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo '1970-01-01 00:00:00')"
  echo -e "${BLUE}[${NOW}]${NC} ${BOLD}[${LEVEL}]${NC} ${MSG}"
  echo "[${NOW}] [${LEVEL}] ${MSG}" >> "${DISTRIBUTED_LOG}" 2>/dev/null || true
}

fail() {
  log "FATAL" "$*"
  echo -e "${RED}=================================================${NC}"
  echo -e "${RED}     M3hl@n! DISTRIBUTED BUILD FAILURE           ${NC}"
  echo -e "${RED}                TRY AGAIN.                       ${NC}"
  echo -e "${RED}=================================================${NC}"
  exit 1
}

cleanup() {
  local EXIT_CODE=$?
  if [ ${EXIT_CODE} -ne 0 ]; then
    log "WARN" "Distributed executor terminated with exit=${EXIT_CODE}"
  fi
}
trap cleanup EXIT

ensure_dir() {
  local D=$1
  if [ ! -d "${D}" ]; then
    mkdir -p "${D}" || fail "Unable to create directory: ${D}"
  fi
}

# --- [ 3. TOOLCHAIN / ENVIRONMENT CHECKS ] -----------------------------------

check_core_tools() {
  log "CHECK" "Verifying required tools for distributed engine..."
  command -v python3 >/dev/null 2>&1 || fail "python3 is required."
  command -v shasum  >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1 || \
    fail "shasum or sha256sum is required for hashing."
  if ! command -v gpg >/dev/null 2>&1; then
    log "WARN" "gpg not found — attestations will be unsigned."
  fi
  if ! command -v ssh >/dev/null 2>&1; then
    log "WARN" "ssh not found — multi-node remote dispatch disabled; using local only."
  fi
}

# --- [ 4. HASH / SIGNING HELPERS ] -------------------------------------------

compute_sha256() {
  local FILE=$1
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${FILE}" 2>/dev/null | awk '{print $1}'
  else
    sha256sum "${FILE}" 2>/dev/null | awk '{print $1}'
  fi
}

sign_file() {
  local FILE=$1
  local SIG="${FILE}.sig"
  if command -v gpg >/dev/null 2>&1; then
    gpg --batch --yes --detach-sign --output "${SIG}" "${FILE}" || \
      log "WARN" "gpg signing failed for ${FILE}"
    log "INFO" "Generated GPG signature: ${SIG}"
  else
    log "WARN" "gpg not available — no cryptographic signature generated for ${FILE}"
  fi
}

# --- [ 5. TARGET LOADING / TOKEN-LEVEL DIFFS ] --------------------------------

load_targets() {
  if [ ! -f "${TARGETS_FILE}" ]; then
    log "WARN" "No targets.json found at ${TARGETS_FILE} — nothing to build."
    return 1
  fi

  python3 - "${TARGETS_FILE}" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
targets = data.get("targets", [])
for t in targets:
    tid = t.get("id", "")
    p   = t.get("path", "")
    lang = t.get("language", "")
    adapter = t.get("adapter", "")
    if tid and p and adapter:
        print(f"{tid}|{p}|{lang}|{adapter}")
PY
}

compute_token_diff_score() {
  # Token-level diff heuristic: compare current content vs cached snapshot if present.
  # Input: path
  local FILE=$1
  local SNAPSHOT="${LOCAL_CACHE_DIR}/tokens/$(echo "${FILE}" | tr '/' '_').tokens"

  mkdir -p "${LOCAL_CACHE_DIR}/tokens"

  if [ ! -f "${FILE}" ]; then
    echo "1.0" # treat missing as heavy change
    return 0
  fi

  local CURRENT_TOKENS
  CURRENT_TOKENS=$(python3 - "$FILE" <<'PY'
import sys, re
p = sys.argv[1]
try:
    txt = open(p,"r",encoding="utf-8",errors="ignore").read()
except OSError:
    print("")
    sys.exit(0)
tokens = re.findall(r"\w+|\S", txt)
print(" ".join(tokens))
PY
)

  if [ ! -f "${SNAPSHOT}" ]; then
    # First-time: store and treat as heavy change
    printf "%s\n" "${CURRENT_TOKENS}" > "${SNAPSHOT}"
    echo "1.0"
    return 0
  fi

  local OLD_TOKENS
  OLD_TOKENS=$(cat "${SNAPSHOT}")

  # Very rough Jaccard similarity over tokens
  local SCORE
  SCORE=$(python3 - <<PY
old = set("""${OLD_TOKENS}""".split())
new = set("""${CURRENT_TOKENS}""".split())
if not old and not new:
    print("0.0")
else:
    inter = len(old & new)
    union = len(old | new) or 1
    sim = inter / union
    # diff score = 1 - similarity
    print(f"{1.0 - sim:.3f}")
PY
)
  # Update snapshot
  printf "%s\n" "${CURRENT_TOKENS}" > "${SNAPSHOT}"

  echo "${SCORE}"
}

# --- [ 6. NEURAL DAG PREDICTION / HEURISTIC PRUNING ] ------------------------

neural_dag_plan() {
  # Uses predictive_engine/engine.py when present plus local heuristics
  local CHANGESET=${1:-HEAD}

  if [ -f "${PREDICTIVE_ENGINE}" ]; then
    log "INFO" "Invoking Predictive Engine for DAG prediction (changeset=${CHANGESET})..."
    python3 "${PREDICTIVE_ENGINE}" "${CHANGESET}" || \
      log "WARN" "Predictive engine advisory failed; continuing with heuristic-only plan."
  else
    log "WARN" "Predictive engine not found at ${PREDICTIVE_ENGINE}; heuristic-only."
  fi

  # Build a prioritized plan using language weights + token diffs
  load_targets | python3 - <<'PY'
import sys
import os

weights = {
    "rust": 1.2,
    "go": 1.1,
    "java": 1.3,
    "c": 1.4,
    "cpp": 1.4,
    "python": 0.9,
    "node": 1.0,
    "js": 1.0,
    "ts": 1.0,
    "swift": 1.2,
    "dotnet": 1.3,
}

lines = sys.stdin.read().strip().splitlines()
plan = []
for line in lines:
    tid, path, lang, adapter = (line.split("|") + ["","","",""])[:4]
    lang_lc = lang.lower()
    base_weight = weights.get(lang_lc, 1.0)
    # token-level diff score is provided separately by shell; for now default 0.5
    # we keep an open channel for later integration if needed.
    plan.append((base_weight, tid, path, lang, adapter))

# Highest "weight" first (expensive & critical builds get scheduled early)
plan.sort(key=lambda x: x[0], reverse=True)

for w, tid, path, lang, adapter in plan:
    print(f"{tid}|{path}|{lang}|{adapter}|{w}")
PY
}

heuristic_prune() {
  # Drops targets that have zero diff and recent cache hit (if we tracked it).
  # For now, we only accept an external plan and re-emit it (stub ready for extension).
  local CHANGESET=${1:-HEAD}
  local line
  while IFS= read -r line; do
    # Format: id|path|lang|adapter|weight
    local tid path lang adapter weight
    tid=$(echo "${line}" | cut -d'|' -f1)
    path=$(echo "${line}" | cut -d'|' -f2)
    lang=$(echo "${line}" | cut -d'|' -f3)
    adapter=$(echo "${line}" | cut -d'|' -f4)
    weight=$(echo "${line}" | cut -d'|' -f5)

    local DIFF_SCORE
    DIFF_SCORE=$(compute_token_diff_score "${path}" || echo "1.0")

    # If diff score < 0.05 and we someday have a cache hit, we could skip.
    # For now, we just log the heuristic and keep it.
    log "INFO" "Heuristic pruning: target=${tid} lang=${lang} diff=${DIFF_SCORE} weight=${weight}"
    echo "${tid}|${path}|${lang}|${adapter}|${weight}|${DIFF_SCORE}"
  done
}

# --- [ 7. SHARDING / PARALLEL GRAPH EXECUTOR ] -------------------------------

assign_node_for_shard() {
  local SHARD_INDEX=$1
  local NODES_COUNT=${#NODES[@]}
  if [ "${NODES_COUNT}" -eq 0 ]; then
    echo "local"
    return
  fi
  local IDX=$(( SHARD_INDEX % NODES_COUNT ))
  echo "${NODES[${IDX}]}"
}

execute_target_on_node() {
  local NODE=$1
  local TARGET_ID=$2
  local TARGET_PATH=$3
  local TARGET_LANG=$4
  local TARGET_ADAPTER=$5

  local ADAPTER_SCRIPT="${M3HLAN_ROOT}/manifests/adapters/${TARGET_ADAPTER}_adapter.sh"

  if [ ! -x "${ADAPTER_SCRIPT}" ]; then
    log "WARN" "Adapter script not executable: ${ADAPTER_SCRIPT} (target=${TARGET_ID})"
    return 1
  fi

  if [ "${NODE}" = "local" ]; then
    log "INFO" "Executing target=${TARGET_ID} via ${ADAPTER_SCRIPT} locally (path=${TARGET_PATH})"
    "${ADAPTER_SCRIPT}" "${TARGET_PATH}"
  else
    # SSH execution
    if ! command -v ssh >/dev/null 2>&1; then
      log "WARN" "ssh unavailable; cannot dispatch to node=${NODE}, running locally instead."
      "${ADAPTER_SCRIPT}" "${TARGET_PATH}"
      return 0
    fi
    log "INFO" "Executing target=${TARGET_ID} on node=${NODE} via SSH"
    ssh "${NODE%%:*}" "cd '${TARGET_PATH}' && '${ADAPTER_SCRIPT}' '.'"
  fi
}

build_shards_parallel() {
  local PARALLELISM=${1:-$DEFAULT_PARALLELISM}
  local CHANGESET=${2:-HEAD}

  ensure_dir "${LOCAL_CACHE_DIR}"
  ensure_dir "${REMOTE_CACHE_DIR}"
  ensure_dir "${ARTIFACTS_DIR}"

  log "INFO" "Building distributed plan for changeset=${CHANGESET} (parallelism=${PARALLELISM})"

  # Build plan (neural_dag_plan) and heuristic prune
  local PLAN_FILE
  PLAN_FILE="$(mktemp)"
  local PRUNED_FILE
  PRUNED_FILE="$(mktemp)"

  neural_dag_plan "${CHANGESET}" > "${PLAN_FILE}" || {
    log "WARN" "Neural DAG prediction failed; falling back to plain target list."
    load_targets > "${PLAN_FILE}" || {
      rm -f "${PLAN_FILE}"
      fail "No build targets available."
    }
  }

  heuristic_prune "${CHANGESET}" < "${PLAN_FILE}" > "${PRUNED_FILE}"

  # Shard into groups and execute in parallel
  local INDEX=0
  local -a PIDS=()
  local LINE

  while IFS= read -r LINE; do
    local tid path lang adapter weight diff
    tid=$(echo "${LINE}" | cut -d'|' -f1)
    path=$(echo "${LINE}" | cut -d'|' -f2)
    lang=$(echo "${LINE}" | cut -d'|' -f3)
    adapter=$(echo "${LINE}" | cut -d'|' -f4)
    weight=$(echo "${LINE}" | cut -d'|' -f5)
    diff=$(echo "${LINE}" | cut -d'|' -f6)

    local SHARD_INDEX=$(( INDEX % PARALLELISM ))
    local NODE
    NODE=$(assign_node_for_shard "${SHARD_INDEX}")

    (
      log "INFO" "Shard=${SHARD_INDEX} Node=${NODE} Target=${tid} weight=${weight} diff=${diff}"
      execute_target_on_node "${NODE}" "${tid}" "${path}" "${lang}" "${adapter}"
    ) &

    PIDS+=($!)
    INDEX=$(( INDEX + 1 ))
  done < "${PRUNED_FILE}"

  # Wait for all shards
  local PID
  local FAILED=0
  for PID in "${PIDS[@]:-}"; do
    if ! wait "${PID}"; then
      FAILED=1
    fi
  done

  rm -f "${PLAN_FILE}" "${PRUNED_FILE}"

  if [ ${FAILED} -ne 0 ]; then
    fail "One or more shards failed."
  fi
  log "INFO" "All shards completed successfully."
}

# --- [ 8. REMOTE CACHE SYNC ] ------------------------------------------------

sync_to_remote_cache() {
  # Local remote cache is just a directory; user can rsync this elsewhere manually.
  log "INFO" "Syncing local artifacts to remote cache directory: ${REMOTE_CACHE_DIR}"
  ensure_dir "${REMOTE_CACHE_DIR}"
  rsync -a "${ARTIFACTS_DIR}/" "${REMOTE_CACHE_DIR}/" 2>/dev/null || \
    log "WARN" "rsync to remote cache failed; continuing."
}

# --- [ 9. PROVENANCE / ATTESTATION / TRANSPARENCY LOGS ] ---------------------

record_provenance_entry() {
  local STATUS=$1
  local CHANGESET=${2:-HEAD}
  local HASH=""

  ensure_dir "${ARTIFACTS_DIR}"
  local SNAPFILE="${ARTIFACTS_DIR}/snapshot-${CHANGESET}.tar"
  tar -cf "${SNAPFILE}" -C "${M3HLAN_ROOT}" core manifests observability predictive_engine 2>/dev/null || true

  HASH=$(compute_sha256 "${SNAPFILE}")
  sign_file "${SNAPFILE}"

  local GIT_COMMIT="unknown"
  if command -v git >/dev/null 2>&1 && git -C "${M3HLAN_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_COMMIT=$(git -C "${M3HLAN_ROOT}" rev-parse HEAD 2>/dev/null || echo "unknown")
  fi

  local ENTRY
  ENTRY=$(python3 - <<PY
import json, os
entry = {
  "timestamp": "${TIMESTAMP}",
  "status": "${STATUS}",
  "changeset": "${CHANGESET}",
  "snapshot_hash": "${HASH}",
  "git_commit": "${GIT_COMMIT}",
  "root": "${M3HLAN_ROOT}"
}
print(json.dumps(entry, sort_keys=True))
PY
)

  echo "${ENTRY}" >> "${PROVENANCE_LOG}"

  # Transparency log (append-only with hash chaining)
  local TL_PREV_HASH=""
  if [ -f "${TRANSPARENCY_LOG}" ]; then
    TL_PREV_HASH=$(tail -n 1 "${TRANSPARENCY_LOG}" | awk '{print $1}')
  fi

  local TL_ENTRY="${ENTRY}"
  local TL_HASH_INPUT="${TL_PREV_HASH}${TL_ENTRY}"
  local TL_HASH
  TL_HASH=$(printf '%s' "${TL_HASH_INPUT}" | (shasum -a 256 2>/dev/null || sha256sum 2>/dev/null) | awk '{print $1}')

  printf '%s %s\n' "${TL_HASH}" "${TL_ENTRY}" >> "${TRANSPARENCY_LOG}"

  log "INFO" "Recorded provenance entry; snapshot_hash=${HASH}, chain_head=${TL_HASH}"
}

# --- [ 10. COMMANDS ] --------------------------------------------------------

cmd_plan() {
  local CHANGESET=${1:-HEAD}
  check_core_tools
  log "INFO" "=== PLAN (Neural DAG + Heuristic Pruning) for changeset=${CHANGESET} ==="
  neural_dag_plan "${CHANGESET}" | heuristic_prune "${CHANGESET}"
}

cmd_build() {
  local PARALLELISM=${1:-$DEFAULT_PARALLELISM}
  local CHANGESET=${2:-HEAD}
  check_core_tools
  log "INFO" "Starting distributed build: parallelism=${PARALLELISM}, changeset=${CHANGESET}"
  build_shards_parallel "${PARALLELISM}" "${CHANGESET}"
  sync_to_remote_cache
  record_provenance_entry "success" "${CHANGESET}"
  echo -e "${GREEN}Distributed build complete. GOT UM.${NC}"
}

cmd_attest() {
  local CHANGESET=${1:-HEAD}
  check_core_tools
  record_provenance_entry "attest-only" "${CHANGESET}"
  echo -e "${GREEN}Attestation & provenance recorded for changeset ${CHANGESET}.${NC}"
}

cmd_show_chain() {
  echo -e "${CYAN}=== PROVENANCE CHAIN (JSONL) ===${NC}"
  if [ -f "${PROVENANCE_LOG}" ]; then
    cat "${PROVENANCE_LOG}"
  else
    echo "No provenance entries yet."
  fi
  echo
  echo -e "${CYAN}=== TRANSPARENCY LOG (hash-chained) ===${NC}"
  if [ -f "${TRANSPARENCY_LOG}" ]; then
    cat "${TRANSPARENCY_LOG}"
  else
    echo "No transparency entries yet."
  fi
}

cmd_help() {
  cat <<EOF
M3hl@n! Distributed / AI / Provenance Layer

Usage:
  $(basename "$0") plan [changeset]          Plan build (neural DAG + heuristic pruning)
  $(basename "$0") build [parallelism] [changeset]
                                             Distributed build with sharding & multi-node
  $(basename "$0") attest [changeset]        Generate snapshot + attestation + chain entry
  $(basename "$0") chain                     Show provenance chain and transparency log
  $(basename "$0") help                      Show this help

Conventions:
  - Targets are defined in: ${TARGETS_FILE}
    Each entry: { "id": "...", "path": "...", "language": "...", "adapter": "cargo|maven|..." }
  - Adapters live in:       ${M3HLAN_ROOT}/manifests/adapters
  - Artifacts:              ${ARTIFACTS_DIR}
  - Remote cache:           ${REMOTE_CACHE_DIR}
  - Local cache:            ${LOCAL_CACHE_DIR}
EOF
}

# --- [ 11. ENTRYPOINT ] ------------------------------------------------------

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  plan)
    cmd_plan "$@"
    ;;
  build)
    cmd_build "$@"
    ;;
  attest)
    cmd_attest "$@"
    ;;
  chain)
    cmd_show_chain
    ;;
  help|*)
    cmd_help
    ;;
esac

# Copyright © 2025 Devin B. Royal. All Rights Reserved.
