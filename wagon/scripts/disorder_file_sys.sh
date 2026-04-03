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
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/PLEASE_LOVE_ME_${counter}"
        ((counter++))
    done
    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        rename_files "${entry%/}"
    done
}

create_files() {
    local dir="$1"
    local has_subdirs=0
    for entry in "$dir"/*/; do
        [ -d "$entry" ] && { has_subdirs=1; break; }
    done
    if [ "$has_subdirs" -eq 0 ]; then
        for i in {1..50}; do
            local fakedir="$dir/PLEASE_LOVE_ME_${i}"
            mkdir -p "$fakedir"
            for j in {1..20}; do
                > "$fakedir/PLEASE_LOVE_ME_${j}"
            done
        done
    else
        for entry in "$dir"/*/; do
            [ -d "$entry" ] || continue
            entry="${entry%/}"
            for i in {1..20}; do
                > "$entry/PLEASE_LOVE_ME_${i}"
            done
            create_files "$entry"
        done
    fi
}

rename_dirs() {
    local dir="$1"
    # Rename subdirs bottom-up (recurse first, rename after)
    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        entry="${entry%/}"
        rename_dirs "$entry"
        mv "$entry" "${entry%/*}/PLEASE_LOVE_ME_DIR_${dir_counter}"
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

# Rename subdirs in /home and /var/www last, bottom-up
for target in /home /var/www; do
    [ -d "$target" ] || { echo "[SKIP] $target not found"; continue; }
    echo "[*] Renaming dirs in $target"
    rename_dirs "$target"
done