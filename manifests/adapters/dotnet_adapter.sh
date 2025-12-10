# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v dotnet >/dev/null 2>&1; then
    echo "[M3hl@n!/dotnet] ERROR: dotnet SDK not found in PATH."
    exit 1
fi

echo "[M3hl@n!/dotnet] Restoring, building, and testing .NET solution in ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && dotnet restore && dotnet build && dotnet test )
echo "[M3hl@n!/dotnet] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.