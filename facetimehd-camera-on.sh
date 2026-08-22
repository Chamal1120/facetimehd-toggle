#!/bin/bash
# facetimehd-camera-on.sh
# Loads the camera module and disables ASPM (avoids image artifacts while
# the camera is in use; trades away CPU C6/C7 residency until turned off).
#
# Combines both steps into one script so the GUI only needs a single
# pkexec prompt, and the same script can be reused by other callers
# (e.g. this could be extended later for a resume hook) without duplicating
# the logic.

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

modprobe facetimehd
"$ASPM_SET_SCRIPT" "$ROOT_COMPLEX" "$ENDPOINT" 0
