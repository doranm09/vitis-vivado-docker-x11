#!/usr/bin/env bash
# Source this file in shells or GUI launchers to expose Vitis/Vivado tools.
# It is safe to source before the tools are installed.

INSTALL_DIR="${XILINX_INSTALL_DIR:-/opt/Xilinx}"
VERSION="${XILINX_VERSION:-2022.2}"

if [[ -f "${INSTALL_DIR}/Vitis/${VERSION}/settings64.sh" ]]; then
  # shellcheck disable=SC1090
  source "${INSTALL_DIR}/Vitis/${VERSION}/settings64.sh"
elif [[ -f "${INSTALL_DIR}/Vivado/${VERSION}/settings64.sh" ]]; then
  # shellcheck disable=SC1090
  source "${INSTALL_DIR}/Vivado/${VERSION}/settings64.sh"
else
  return 0 2>/dev/null || exit 0
fi
