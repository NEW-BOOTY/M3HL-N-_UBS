# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v mvn >/dev/null 2>&1; then
    echo "[M3hl@n!/maven] ERROR: mvn (Maven) not found in PATH."
    exit 1
fi

if [ ! -f "${PROJECT_DIR}/pom.xml" ]; then
    echo "[M3hl@n!/maven] ERROR: pom.xml not found in ${PROJECT_DIR}."
    exit 1
fi

echo "[M3hl@n!/maven] Running mvn -q -f ${PROJECT_DIR}/pom.xml clean verify..."
mvn -q -f "${PROJECT_DIR}/pom.xml" clean verify
echo "[M3hl@n!/maven] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.