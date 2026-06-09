#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DISPLAY:-}" ]]; then
  echo "DISPLAY is not set. Start this from a graphical Linux session, or export DISPLAY first." >&2
  exit 1
fi

if ! command -v xhost >/dev/null 2>&1; then
  echo "xhost is not installed on the host. On Ubuntu/Debian: sudo apt-get install x11-xserver-utils" >&2
  exit 1
fi

host_user="$(id -un)"

if xhost +SI:localuser:"${host_user}" >/dev/null; then
  echo "Enabled X11 access for local user: ${host_user}"
else
  cat >&2 <<MSG
Could not enable X11 access with '+SI:localuser:${host_user}'.
For a trusted single-user lab machine, broader fallback:

  xhost +local:

Avoid 'xhost +' because it disables X access control globally.
MSG
  exit 1
fi
