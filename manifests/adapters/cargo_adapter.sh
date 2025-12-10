# Copyright © 2025 Devin B. Royal. All Rights Reserved.
# Project: M3hl@n! Unified Build System (Original IP).
# SPDX-License-Identifier: LicenseRef-M3hlan-Enterprise#!/bin/bash
set -euo pipefail

PROJECT_DIR=${1:-.}

if ! command -v cargo >/dev/null 2>&1; then
    echo "[M3hl@n!/cargo] ERROR: cargo not found in PATH."
    exit 1
fi

echo "[M3hl@n!/cargo] Building Rust project at ${PROJECT_DIR}..."
cargo build --manifest-path "${PROJECT_DIR}/Cargo.toml"
echo "[M3hl@n!/cargo] GOT UM."


# Copyright © 2025 Devin B. Royal. All Rights Reserved.