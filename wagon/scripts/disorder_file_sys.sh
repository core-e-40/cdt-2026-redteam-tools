#!/bin/bash

TARGET_DIRS=(
    /opt
    /srv
    /var/www
    /home
    /var/log
)

counter=1
dir_counter=1

rename_files() {
    local dir="$1"
    local depth="${2:-0}"
    [ "$depth" -gt 6 ] && return

    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/PLEASE_LOVE_ME_${counter}" 2>/dev/null
        ((counter++))
    done
    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        rename_files "${entry%/}" $((depth + 1))
    done
}

create_files() {
    local dir="$1"
    local depth="${2:-0}"
    [ "$depth" -gt 6 ] && return

    local has_subdirs=0
    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        # Skip dirs we already created
        [[ "${entry%/}" == *"PLEASE_LOVE_ME"* ]] && continue
        has_subdirs=1
        break
    done

    if [ "$has_subdirs" -eq 0 ]; then
        for i in {1..50}; do
            mkdir -p "$dir/PLEASE_LOVE_ME_${i}" 2>/dev/null
            for j in {1..20}; do
                > "$dir/PLEASE_LOVE_ME_${i}/PLEASE_LOVE_ME_${j}" 2>/dev/null
            done
        done
    else
        for entry in "$dir"/*/; do
            [ -d "$entry" ] || continue
            entry="${entry%/}"
            [[ "$entry" == *"PLEASE_LOVE_ME"* ]] && continue
            for i in {1..20}; do
                > "$entry/PLEASE_LOVE_ME_${i}" 2>/dev/null
            done
            create_files "$entry" $((depth + 1))
        done
    fi
}

rename_dirs() {
    local dir="$1"
    local depth="${2:-0}"
    [ "$depth" -gt 6 ] && return

    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        entry="${entry%/}"
        rename_dirs "$entry" $((depth + 1))
        mv "$entry" "${entry%/*}/PLEASE_LOVE_ME_DIR_${dir_counter}" 2>/dev/null
        ((dir_counter++))
    done
}

cd /

for target in "${TARGET_DIRS[@]}"; do
    [ -d "$target" ] || { echo "[SKIP] $target not found"; continue; }
    echo "[*] Renaming files in $target"
    rename_files "$target"
    echo "[*] Creating decoy files in $target"
    create_files "$target"
done

for target in /home /var/www; do
    [ -d "$target" ] || continue
    echo "[*] Renaming dirs in $target"
    rename_dirs "$target"
done