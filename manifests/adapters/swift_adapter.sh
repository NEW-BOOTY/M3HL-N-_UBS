# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v swift >/dev/null 2>&1; then
    echo "[M3hl@n!/swift] ERROR: swift not found in PATH."
    exit 1
fi

echo "[M3hl@n!/swift] Running swift build in ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && swift build )
echo "[M3hl@n!/swift] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.