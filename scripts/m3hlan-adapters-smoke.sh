# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise

#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
ROOT="${M3HLAN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ADAPTERS_DIR="${ROOT}/manifests/adapters"

echo "[M3hl@n!/adapters] Running adapter presence & exec sanity checks..."

failures=0

check_adapter() {
  local name="$1"
  local script="${ADAPTERS_DIR}/${name}_adapter.sh"

  if [ ! -x "${script}" ]; then
    echo "[adapters] MISSING or not executable: ${name}_adapter.sh"
    failures=$((failures + 1))
    return
  fi

  if ! head -n 1 "${script}" >/dev/null 2>&1; then
    echo "[adapters] UNREADABLE: ${name}_adapter.sh"
    failures=$((failures + 1))
    return
  fi

  echo "[adapters] OK: ${name}_adapter.sh (exists + executable)"
}

for a in cargo maven gradle npm yarn go cmake pip poetry swift dotnet; do
  check_adapter "${a}"
done

if [ ${failures} -gt 0 ]; then
  echo "[adapters] Completed with ${failures} issues."
  # Non-fatal to upgrade process, but warning reported
  exit 0
fi

echo "[adapters] All adapters structurally sane. GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.
