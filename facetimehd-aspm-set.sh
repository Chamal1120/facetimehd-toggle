#!/bin/bash
# facetimehd-aspm-set.sh <root_complex> <endpoint> <aspm_setting>
#
# Generic ASPM setter, refactored from the original mcgrof aspm-tuning.sh.
# Takes the PCI addresses and desired setting as arguments instead of
# hardcoding them, so one script covers both the "enable" and "disable"
# cases instead of maintaining two near-duplicate copies.
#
# aspm_setting: 0 = L0 only (ASPM disabled), 3 = L1 and L0s (ASPM enabled)

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <root_complex> <endpoint> <aspm_setting 0|3>" >&2
    exit 2
fi

ROOT_COMPLEX="$1"
ENDPOINT="$2"
ASPM_SETTING="$3"

if [[ $(id -u) != 0 ]]; then
    echo "This needs to be run as root" >&2
    exit 1
fi

aspm_setting_to_string() {
    case "$1" in
        0) echo "L0 only, ASPM disabled" ;;
        1) echo "L0s only" ;;
        2) echo "L1 only" ;;
        3) echo "L1 and L0s" ;;
        *) echo "Invalid" ;;
    esac
}

# Fixed from the original: was checking an unset $ROOT_COMPLEXT, which made
# the presence check a no-op (grep -c "" matches every lspci line).
device_present() {
    local addr="$1"
    lspci -s "$addr" | grep -q .
}

if ! device_present "$ROOT_COMPLEX"; then
    echo "Root complex $ROOT_COMPLEX is not present" >&2
    exit 1
fi

if ! device_present "$ENDPOINT"; then
    echo "Endpoint $ENDPOINT is not present" >&2
    exit 1
fi

find_aspm_byte_address() {
    local addr="$1"
    local search count=1
    search=$(setpci -s "$addr" 34.b)

    while [[ "$search" != "10" && $count -le 20 ]]; do
        local end
        end=$(setpci -s "$addr" "${search}.b")
        if [[ "$end" == "10" ]]; then
            printf "%X\n" "$(( 0x${search} + 0x10 ))"
            return 0
        fi
        search=$(printf "%X" "$(( 0x${search} + 1 ))")
        search=$(setpci -s "$addr" "${search}.b")
        ((count++))
    done

    return 1
}

set_aspm_byte() {
    local addr="$1"
    local byte_addr
    if ! byte_addr=$(find_aspm_byte_address "$addr"); then
        echo "No ASPM byte could be found for $(lspci -s "$addr")" >&2
        return 1
    fi

    local current desired
    current=$(setpci -s "$addr" "${byte_addr}.b")
    current=$(printf "%X" "0x${current}")
    desired=$(printf "%X" "$(( (0x${current} & ~0x7) | ASPM_SETTING ))")

    echo "$(lspci -s "$addr")"
    printf "\t0x%s : 0x%s --> 0x%s ... " "$byte_addr" "$current" "$desired"

    if [[ "$current" == "$desired" ]]; then
        echo "[SUCCESS] (already set)"
        echo -e "\t$(aspm_setting_to_string "$ASPM_SETTING")"
        return 0
    fi

    setpci -s "$addr" "${byte_addr}.b=${ASPM_SETTING}:3"
    sleep 1

    local actual
    actual=$(setpci -s "$addr" "${byte_addr}.b")
    actual=$(printf "%X" "0x${actual}")

    if [[ "$actual" != "$desired" ]]; then
        echo "[FAIL] (0x${actual})"
        return 1
    fi

    echo "[SUCCESS]"
    echo -e "\t$(aspm_setting_to_string "$ASPM_SETTING")"
    return 0
}

echo "Root complex:"
set_aspm_byte "$ROOT_COMPLEX"
echo
echo "Endpoint:"
set_aspm_byte "$ENDPOINT"
