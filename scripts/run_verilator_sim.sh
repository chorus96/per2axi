#!/usr/bin/env bash
# Regenerate and launch the Verilator simulation for the per2axi smoke testbench.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

"${script_dir}/gen_verilator_sim.sh"
cd "${repo_root}"
verilator -f "${script_dir}/verilator_sim.f" "$@"
"${repo_root}/obj_dir/Vtb_per2axi"
