# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise

#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
ROOT="${M3HLAN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[M3hl@n!/doctor] Environment diagnostic"

check() {
  local tool="$1"
  if command -v "${tool}" >/dev/null 2>&1; then
    echo "  [OK] ${tool}: $(command -v "${tool}")"
  else
    echo "  [!!] ${tool}: MISSING"
  fi
}

echo "Core:"
check bash
check python3
check git
check make

echo
echo "Polyglot:"
for t in cargo mvn gradle npm yarn go cmake ninja pip3 poetry swift dotnet; do
  check "${t}"
done

echo
echo "[M3hl@n!/doctor] Diagnostic complete."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.
