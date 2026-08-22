#!/bin/bash
# facetimehd-camera-off.sh
# Unloads the camera module and re-enables ASPM (lets the CPU reach C6/C7
# again). Used by both the GUI toggle and the suspend hook.

set -euo pipefail

LOCK_FILE="/var/lock/facetimehd.lock"
ROOT_COMPLEX="00:1c.1"
ENDPOINT="02:00.0"
ASPM_SET_SCRIPT="/usr/local/bin/facetimehd-aspm-set.sh"

exec 9>"$LOCK_FILE"
if ! flock -w 5 9; then
    echo "Could not acquire facetimehd lock (another operation in progress)" >&2
    exit 1
fi

# Ignore "module not loaded" errors - already off is a success case, both
# for the GUI (idempotent toggle) and the sleep hook (camera may already
# be off when the lid closes).
modprobe -r facetimehd 2>/dev/null || true
"$ASPM_SET_SCRIPT" "$ROOT_COMPLEX" "$ENDPOINT" 3
