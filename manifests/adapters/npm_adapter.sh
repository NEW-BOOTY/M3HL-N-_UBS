# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v npm >/dev/null 2>&1; then
    echo "[M3hl@n!/npm] ERROR: npm not found in PATH."
    exit 1
fi

echo "[M3hl@n!/npm] Installing and building Node project at ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && npm install && npm run build )
echo "[M3hl@n!/npm] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.