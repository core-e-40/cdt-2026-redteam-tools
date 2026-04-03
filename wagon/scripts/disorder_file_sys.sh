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

random_name() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 12
}

random_content() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9 \n' | head -c 256
}

rename_files() {
    local dir="$1"
    local depth="${2:-0}"
    [ "$depth" -gt 6 ] && return

    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mv "$file" "${file%/*}/$(random_name)" 2>/dev/null
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
        has_subdirs=1
        break
    done

    if [ "$has_subdirs" -eq 0 ]; then
        for i in {1..50}; do
            local fakedir="$dir/$(random_name)"
            mkdir -p "$fakedir" 2>/dev/null
            for j in {1..75}; do
                random_content > "$fakedir/$(random_name)" 2>/dev/null
            done
        done
    else
        for entry in "$dir"/*/; do
            [ -d "$entry" ] || continue
            entry="${entry%/}"
            for i in {1..150}; do
                random_content > "$entry/$(random_name)" 2>/dev/null
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
        mv "$entry" "${entry%/*}/$(random_name)" 2>/dev/null
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