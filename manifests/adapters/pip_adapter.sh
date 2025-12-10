# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}
REQ_FILE="${PROJECT_DIR}/requirements.txt"

if ! command -v python3 >/dev/null 2>&1; then
    echo "[M3hl@n!/pip] ERROR: python3 not found in PATH."
    exit 1
fi

if ! command -v pip3 >/dev/null 2>&1; then
    echo "[M3hl@n!/pip] ERROR: pip3 not found in PATH."
    exit 1
fi

if [ -f "${REQ_FILE}" ]; then
    echo "[M3hl@n!/pip] Installing dependencies from ${REQ_FILE}..."
    pip3 install -r "${REQ_FILE}"
fi

if [ -f "${PROJECT_DIR}/pyproject.toml" ]; then
    echo "[M3hl@n!/pip] pyproject.toml detected; running tests via python -m pytest (if available)..."
    if python3 -m pytest --help >/dev/null 2>&1; then
        ( cd "${PROJECT_DIR}" && python3 -m pytest )
    fi
fi

echo "[M3hl@n!/pip] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.