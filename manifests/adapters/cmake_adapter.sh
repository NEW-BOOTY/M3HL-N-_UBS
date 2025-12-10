# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}
BUILD_DIR="${PROJECT_DIR}/build"

mkdir -p "${BUILD_DIR}"

GENERATOR="Unix Makefiles"
if command -v ninja >/dev/null 2>&1; then
    GENERATOR="Ninja"
fi

if ! command -v cmake >/dev/null 2>&1; then
    echo "[M3hl@n!/cmake] ERROR: cmake not found in PATH."
    exit 1
fi

echo "[M3hl@n!/cmake] Configuring C/C++ project with ${GENERATOR} in ${BUILD_DIR}..."
( cd "${BUILD_DIR}" && cmake -G "${GENERATOR}" .. )

if command -v ninja >/dev/null 2>&1; then
    echo "[M3hl@n!/cmake] Building via ninja..."
    ( cd "${BUILD_DIR}" && ninja )
else
    echo "[M3hl@n!/cmake] Building via make..."
    ( cd "${BUILD_DIR}" && make )
fi

echo "[M3hl@n!/cmake] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.