#!/usr/bin/env bash
set -euo pipefail

# Prepare an Xauthority file that can be bind-mounted into the container.
# This is safer than broad `xhost +local:` access.

DISPLAY_VALUE="${DISPLAY:-:0}"
XAUTH_FILE="${XAUTHORITY_FILE:-/tmp/.docker.xauth}"
SOURCE_XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"

if ! command -v xauth >/dev/null 2>&1; then
  echo "ERROR: xauth is not installed on the host." >&2
  echo "Install it with your distro package manager, for example: sudo apt-get install xauth" >&2
  exit 1
fi

if [[ "${DISPLAY_VALUE}" =~ ^:([0-9]+)(\..*)?$ ]]; then
  display_num="${BASH_REMATCH[1]}"
  if [[ ! -S "/tmp/.X11-unix/X${display_num}" ]]; then
    echo "WARNING: /tmp/.X11-unix/X${display_num} was not found." >&2
    echo "The X11 socket mount may fail if your DISPLAY is not a local X display." >&2
  fi
fi

rm -f "${XAUTH_FILE}"
touch "${XAUTH_FILE}"
chmod 600 "${XAUTH_FILE}"

# Prefer the currently active Xauthority database, but do not fail if it is missing.
if [[ -f "${SOURCE_XAUTH}" ]]; then
  XAUTHORITY="${SOURCE_XAUTH}" xauth nlist "${DISPLAY_VALUE}" 2>/dev/null \
    | sed -e 's/^..../ffff/' \
    | xauth -f "${XAUTH_FILE}" nmerge - 2>/dev/null || true
else
  xauth nlist "${DISPLAY_VALUE}" 2>/dev/null \
    | sed -e 's/^..../ffff/' \
    | xauth -f "${XAUTH_FILE}" nmerge - 2>/dev/null || true
fi

if ! xauth -f "${XAUTH_FILE}" list >/dev/null 2>&1 || [[ ! -s "${XAUTH_FILE}" ]]; then
  cat >&2 <<MSG
WARNING: Could not populate ${XAUTH_FILE} with an Xauthority cookie.

You can either troubleshoot Xauthority or use this less strict lab-only fallback:

  xhost +local:

After testing, revoke it with:

  xhost -local:

MSG
else
  cat <<MSG
X11 auth prepared.

DISPLAY=${DISPLAY_VALUE}
XAUTHORITY_FILE=${XAUTH_FILE}

Now run, for example:

  docker compose run --rm xilinx-x11-ssh vivado
  docker compose run --rm xilinx-x11-ssh vitis
  docker compose run --rm xilinx-x11 xeyes

MSG
fi
