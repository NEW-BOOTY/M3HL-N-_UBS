# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if command -v gradle >/dev/null 2>&1; then
    GRADLE_CMD="gradle"
elif [ -x "${PROJECT_DIR}/gradlew" ]; then
    GRADLE_CMD="${PROJECT_DIR}/gradlew"
else
    echo "[M3hl@n!/gradle] ERROR: gradle/gradlew not found."
    exit 1
fi

echo "[M3hl@n!/gradle] Running ${GRADLE_CMD} build in ${PROJECT_DIR}..."
( cd "${PROJECT_DIR}" && "${GRADLE_CMD}" build )
echo "[M3hl@n!/gradle] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.