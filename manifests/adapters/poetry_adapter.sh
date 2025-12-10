# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v poetry >/dev/null 2>&1; then
    echo "[M3hl@n!/poetry] ERROR: poetry not found in PATH."
    exit 1
fi

echo "[M3hl@n!/poetry] Installing and building Poetry project at ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && poetry install && poetry build )
echo "[M3hl@n!/poetry] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.