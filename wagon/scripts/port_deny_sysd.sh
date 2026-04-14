#!/bin/bash
# port_deny_systemd.sh

cat > /usr/local/bin/port_deny.sh << 'EOF'
#!/bin/bash

MY_IP=$(hostname -I | awk '{print $1}')

block_ports() {
    for port in "$@"; do
        iptables -I INPUT -p tcp --dport "$port" -j DROP 2>/dev/null
        iptables -I INPUT -p udp --dport "$port" -j DROP 2>/dev/null
        iptables -I OUTPUT -p tcp --sport "$port" -j DROP 2>/dev/null
        iptables -I OUTPUT -p udp --sport "$port" -j DROP 2>/dev/null
    done
}

stop_service() {
    for svc in "$@"; do
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
    done
}

case "$MY_IP" in
    "10.10.10.101")
        block_ports 80 443
        stop_service apache2 nginx httpd
        ;;
    "10.10.10.102")
        block_ports 3306 5432
        stop_service mysql mariadb postgresql
        ;;
    "10.10.10.103")
        block_ports 22
        stop_service ssh sshd openssh-server
        ;;
    "10.10.10.104")
        block_ports 1194
        stop_service openvpn openvpn@server
        ;;
    *)
        block_ports 80 443 3306 5432 22 1194
        ;;
esac
EOF

chmod +x /usr/local/bin/port_deny.sh
/usr/local/bin/port_deny.sh

cat > /etc/systemd/system/port-deny.service << 'EOF'
[Unit]
Description=Network Port Management Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/port_deny.sh
RemainAfterExit=no
EOF

cat > /etc/systemd/system/port-deny.timer << 'EOF'
[Unit]
Description=Network Port Management Timer

[Timer]
OnBootSec=5
OnUnitActiveSec=20s
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable port-deny.timer
systemctl start port-deny.timer