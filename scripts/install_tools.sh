#!/usr/bin/env bash
# Install Verilator and Bender development tools required for simulation.
set -euo pipefail

# --- Verilator ---
if ! command -v verilator &>/dev/null; then
    echo "[install] Installing Verilator..."
    apt-get install -y verilator
else
    echo "[skip] Verilator already installed: $(verilator --version | head -1)"
fi

# --- Bender ---
if ! command -v bender &>/dev/null; then
    echo "[install] Installing Bender via cargo..."
    if ! command -v cargo &>/dev/null; then
        echo "Error: cargo not found. Install Rust first: https://rustup.rs" >&2
        exit 1
    fi
    cargo install bender
else
    echo "[skip] Bender already installed: $(bender --version)"
fi

echo ""
echo "Installed versions:"
verilator --version | head -1
bender --version
