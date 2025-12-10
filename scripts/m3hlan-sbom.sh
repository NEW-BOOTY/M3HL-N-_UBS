# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise

#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
ROOT="${M3HLAN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
OUT="${ROOT}/sbom.json"

echo "[M3hl@n!/SBOM] Generating lightweight SBOM at ${OUT}..."

if command -v syft >/dev/null 2>&1; then
  syft dir:"${ROOT}" -o json > "${OUT}"
  echo "[M3hl@n!/SBOM] SBOM generated via syft."
  exit 0
fi

# Fallback: naive file inventory with sha256 hashes
echo "[M3hl@n!/SBOM] syft not found — generating minimal inventory."

tmp="${OUT}.tmp"
{
  echo '{'
  echo '  "name": "M3hl@n! Unified Build System",'
  echo '  "version": "1.0-upgraded",'
  echo '  "artifacts": ['
  first=1
  while IFS= read -r -d "" f; do
    hash="$(shasum -a 256 "${f}" 2>/dev/null | awk "{print \$1}")"
    rel="${f#${ROOT}/}"
    if [ ${first} -eq 0 ]; then
      echo '    ,'
    fi
    first=0
    printf '    { "path": "%s", "sha256": "%s" }' "${rel}" "${hash}"
  done < <(find "${ROOT}" -type f -print0)
  echo
  echo '  ]'
  echo '}'
} > "${tmp}"

mv "${tmp}" "${OUT}"
echo "[M3hl@n!/SBOM] Minimal SBOM inventory written."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.
