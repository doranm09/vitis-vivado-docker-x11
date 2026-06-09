#!/usr/bin/env bash
set -e

# Do not source settings before the installer has populated the persistent volume.
if [[ "${1:-}" == "/usr/local/bin/install-vitis-vivado.sh" || "${1:-}" == "install-vitis-vivado.sh" ]]; then
  exec "$@"
fi

INSTALL_DIR="${XILINX_INSTALL_DIR:-/opt/Xilinx}"
VERSION="${XILINX_VERSION:-2022.2}"

if [[ -f "${INSTALL_DIR}/Vitis/${VERSION}/settings64.sh" || -f "${INSTALL_DIR}/Vivado/${VERSION}/settings64.sh" ]]; then
  # shellcheck disable=SC1091
  source /usr/local/bin/xilinx-env.sh
else
  cat >&2 <<MSG
Vitis/Vivado ${VERSION} is not installed under ${INSTALL_DIR} yet.
Run this first from the project directory:

  docker compose run --rm xilinx-install

MSG
fi

# Make future interactive shells pick up the environment too.
if [[ -w "${HOME:-/tmp}" && ! -f "${HOME}/.xilinx_env_added" ]]; then
  cat >> "${HOME}/.bashrc" <<'BASHRC'

# Vitis/Vivado environment
if [ -f /usr/local/bin/xilinx-env.sh ]; then
  source /usr/local/bin/xilinx-env.sh
fi
BASHRC
  touch "${HOME}/.xilinx_env_added" || true
fi

exec "$@"
