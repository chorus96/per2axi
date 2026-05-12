#!/usr/bin/env bash
# Generate the Verilator argument file for the per2axi simulation target.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
out_file="${script_dir}/verilator_sim.f"

cd "${repo_root}"
bender script -t simulation verilator \
  --vlt-args='--binary --timing --top-module tb_per2axi' \
  > "${out_file}"

# Bender emits leading/trailing separator newlines; drop them to keep the checked-in file lint-clean.
sed -i '1{/^$/d;};${/^$/d;}' "${out_file}"
