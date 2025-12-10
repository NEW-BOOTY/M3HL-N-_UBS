# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise

#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
ROOT="${M3HLAN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[M3hl@n!/heal] Re-running layout normalization & core generator if present..."

if [ -x "${ROOT}/../m3hlan-upgrade-fix.sh" ]; then
  echo "[heal] Found upgrade script — re-invoking."
  ( cd "${ROOT}/.." && ./m3hlan-upgrade-fix.sh )
else
  echo "[heal] Upgrade script not found; performing minimal directory heal."
  mkdir -p "${ROOT}/core" "${ROOT}/manifests" "${ROOT}/manifests/adapters" \
           "${ROOT}/observability" "${ROOT}/ergonomics" \
           "${ROOT}/extensions" "${ROOT}/docs" \
           "${ROOT}/predictive_engine" "${ROOT}/ml_models" \
           "${ROOT}/polyglot_runtime"
fi

echo "[M3hl@n!/heal] Heal sequence complete. GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.
