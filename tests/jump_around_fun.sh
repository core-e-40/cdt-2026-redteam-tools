#!/bin/bash
# prank.sh - run as the target user (no sudo needed)

BASHRC="/etc/bash.bashrc"
POLL_INTERVAL=2

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


get_hash() {
    md5sum "$BASHRC" | awk '{print $1}'
}

apply_prank
LAST_HASH=$(get_hash)

while true; do
    sleep "$POLL_INTERVAL"
    CURRENT_HASH=$(get_hash)
    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
        LAST_HASH=$(get_hash)
    fi
done