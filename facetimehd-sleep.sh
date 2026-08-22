#!/bin/bash
# /usr/lib/systemd/system-sleep/facetimehd-sleep.sh
#
# Ensures the camera is unloaded and ASPM is restored before suspend, so
# it can't interfere with C6/C7 entry while asleep. Reuses the same
# camera-off script as the GUI toggle, so there's only one place that
# knows how to turn the camera off.
#
# systemd-sleep calls this as: facetimehd-sleep.sh {pre|post} {suspend|...}

CAMERA_OFF="/usr/local/bin/facetimehd-camera-off.sh"
STATE_FILE="/tmp/facetimehd_state"

case "$1" in
    pre)
        # Remember whether the camera was on, so it *could* be restored on
        # resume if you want that later - currently we don't auto-restore,
        # since leaving the camera off after resume is the safer default
        # (no surprise artifacts, no surprise C-state impact).
        if grep -q facetimehd /proc/modules 2>/dev/null; then
            echo "was_enabled" > "${STATE_FILE}.pre_sleep"
        else
            echo "was_disabled" > "${STATE_FILE}.pre_sleep"
        fi

        "$CAMERA_OFF"
        ;;
    post)
        # Intentionally left as a no-op: camera stays off after resume.
        # If you'd rather it come back automatically when it was on before
        # sleep, this is where you'd call facetimehd-camera-on.sh based on
        # the contents of "${STATE_FILE}.pre_sleep".
        :
        ;;
esac

exit 0
