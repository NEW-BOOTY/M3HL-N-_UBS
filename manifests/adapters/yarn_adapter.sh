# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v yarn >/dev/null 2>&1; then
    echo "[M3hl@n!/yarn] ERROR: yarn not found in PATH."
    exit 1
fi

echo "[M3hl@n!/yarn] Installing and building Node project with Yarn at ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && yarn install && yarn build )
echo "[M3hl@n!/yarn] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.