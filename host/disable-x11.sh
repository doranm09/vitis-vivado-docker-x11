#!/usr/bin/env bash
set -euo pipefail

if ! command -v xhost >/dev/null 2>&1; then
  echo "xhost is not installed on the host." >&2
  exit 1
fi

host_user="$(id -un)"
xhost -SI:localuser:"${host_user}" >/dev/null || true
echo "Removed X11 access entry for local user: ${host_user}"
