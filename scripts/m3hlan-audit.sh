# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise

#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
ROOT="${M3HLAN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "[M3hl@n!/audit] Filesystem & layout audit for ${ROOT}"

echo "Root:"
ls -1 "${ROOT}"

echo
echo "Core:"
ls -1 "${ROOT}/core" 2>/dev/null || echo "(missing core/)"

echo
echo "Manifests:"
ls -1 "${ROOT}/manifests" 2>/dev/null || echo "(missing manifests/)"

echo
echo "Adapters:"
ls -1 "${ROOT}/manifests/adapters" 2>/dev/null || echo "(missing adapters/)"

echo
echo "Observability:"
ls -1 "${ROOT}/observability" 2>/dev/null || echo "(missing observability/)"

echo
echo "Predictive Engine:"
ls -1 "${ROOT}/predictive_engine" 2>/dev/null || echo "(missing predictive_engine/)"

echo
echo "[M3hl@n!/audit] Audit complete."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.
