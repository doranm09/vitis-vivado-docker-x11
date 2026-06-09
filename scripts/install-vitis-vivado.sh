#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${XILINX_INSTALL_DIR:-/opt/Xilinx}"
VERSION="${XILINX_VERSION:-2022.2}"
EDITION="${XILINX_EDITION:-Vitis Unified Software Platform}"
CONFIG_FILE="${XILINX_CONFIG_FILE:-/config/install_config.txt}"
INSTALLER_DIR="${XILINX_INSTALLER_DIR:-/installers}"
WORK_DIR="${XILINX_WORK_DIR:-/tmp/xilinx-installer}"

already_installed() {
  [[ -f "${INSTALL_DIR}/Vitis/${VERSION}/settings64.sh" ]] || [[ -f "${INSTALL_DIR}/Vivado/${VERSION}/settings64.sh" ]]
}

find_xsetup() {
  local found=""

  if [[ -x "${INSTALLER_DIR}/xsetup" ]]; then
    echo "${INSTALLER_DIR}/xsetup"
    return 0
  fi

  found="$(find "${INSTALLER_DIR}" -maxdepth 4 -type f -name xsetup -perm /111 2>/dev/null | head -n 1 || true)"
  if [[ -n "${found}" ]]; then
    echo "${found}"
    return 0
  fi

  mkdir -p "${WORK_DIR}"

  # Single-file download archive, e.g. Xilinx_Unified_2022.2_1014_8888.tar.gz
  local tarball=""
  tarball="$(find "${INSTALLER_DIR}" -maxdepth 1 -type f \( -name 'Xilinx_Unified*2022.2*.tar.gz' -o -name 'Xilinx_Unified*2022.2*.tgz' -o -name '*.tar.gz' \) | head -n 1 || true)"
  if [[ -n "${tarball}" ]]; then
    echo "Extracting installer archive: ${tarball}" >&2
    tar -xf "${tarball}" -C "${WORK_DIR}"
    found="$(find "${WORK_DIR}" -type f -name xsetup -perm /111 | head -n 1 || true)"
    if [[ -n "${found}" ]]; then
      echo "${found}"
      return 0
    fi
  fi

  # Web/self-extracting installer, e.g. Xilinx_Unified_2022.2_1014_8888_Lin64.bin
  local bin=""
  bin="$(find "${INSTALLER_DIR}" -maxdepth 1 -type f \( -name 'Xilinx_Unified*2022.2*Lin64*.bin' -o -name '*.bin' \) | head -n 1 || true)"
  if [[ -n "${bin}" ]]; then
    echo "Extracting self-extracting installer: ${bin}" >&2
    local runnable_bin="${WORK_DIR}/$(basename "${bin}")"
    cp "${bin}" "${runnable_bin}"
    chmod +x "${runnable_bin}"
    # Most Xilinx/AMD self-extracting installers support --target and --noexec.
    # If this fails, extract it manually into ./installers so xsetup is visible.
    "${runnable_bin}" --target "${WORK_DIR}" --noexec || {
      echo "ERROR: Could not auto-extract ${bin}." >&2
      echo "Try extracting it manually on the host and place the extracted directory under ./installers." >&2
      exit 1
    }
    found="$(find "${WORK_DIR}" -type f -name xsetup -perm /111 | head -n 1 || true)"
    if [[ -n "${found}" ]]; then
      echo "${found}"
      return 0
    fi
  fi

  return 1
}

mkdir -p "${INSTALL_DIR}"

if already_installed; then
  echo "Vitis/Vivado ${VERSION} already appears to be installed in ${INSTALL_DIR}."
  echo "Nothing to do. The Docker volume is already populated."
  exit 0
fi

XSETUP="$(find_xsetup || true)"
if [[ -z "${XSETUP}" ]]; then
  cat >&2 <<ERR
ERROR: Could not find xsetup.

Put one of the following under ./installers on the host:
  1. The extracted AMD/Xilinx installer directory that contains xsetup, or
  2. The 2022.2 SFD .tar.gz installer, or
  3. The 2022.2 Linux self-extracting .bin installer.

Recommended for repeatable Docker installs: use the full SFD/offline installer archive.
ERR
  exit 1
fi

chmod +x "${XSETUP}" || true

echo "Using xsetup: ${XSETUP}"
echo "Install destination: ${INSTALL_DIR}"

if [[ -s "${CONFIG_FILE}" ]]; then
  echo "Using installer config: ${CONFIG_FILE}"
  "${XSETUP}" \
    --agree XilinxEULA,3rdPartyEULA,WebTalkTerms \
    --batch Install \
    --config "${CONFIG_FILE}"
else
  echo "No ${CONFIG_FILE} found; using command-line product/edition/location defaults."
  echo "Edition: ${EDITION}"
  "${XSETUP}" \
    --agree XilinxEULA,3rdPartyEULA,WebTalkTerms \
    --batch Install \
    --edition "${EDITION}" \
    --location "${INSTALL_DIR}"
fi

if already_installed; then
  echo "Install complete. Found settings64.sh for Vitis/Vivado ${VERSION}."
else
  echo "WARNING: Install command returned, but settings64.sh was not found under ${INSTALL_DIR}/{Vitis,Vivado}/${VERSION}." >&2
  echo "Check the xinstall logs printed by xsetup." >&2
  exit 2
fi
