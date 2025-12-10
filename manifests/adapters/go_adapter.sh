# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v go >/dev/null 2>&1; then
    echo "[M3hl@n!/go] ERROR: go not found in PATH."
    exit 1
fi

echo "[M3hl@n!/go] Tidying and testing Go modules at ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && go mod tidy && go test ./... && go build ./... )
echo "[M3hl@n!/go] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.