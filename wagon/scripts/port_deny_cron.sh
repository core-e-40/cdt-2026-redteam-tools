#!/bin/bash
# port_deny_cron.sh

cat > /usr/local/bin/port_deny.sh << 'EOF'
#!/bin/bash

# detect which machine we are based on IP
MY_IP=$(hostname -I | awk '{print $1}')

block_ports() {
    for port in "$@"; do
        # block incoming
        iptables -I INPUT -p tcp --dport "$port" -j DROP 2>/dev/null
        iptables -I INPUT -p udp --dport "$port" -j DROP 2>/dev/null
        # block outgoing responses
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
        # SCP-APACHE-01
        block_ports 80 443
        stop_service apache2 nginx httpd
        ;;
    "10.10.10.102")
        # SCP-DATABASE-01
        block_ports 3306 5432
        stop_service mysql mariadb postgresql
        ;;
    "10.10.10.103")
        # SCP-OPENSSH-01
        block_ports 22
        stop_service ssh sshd openssh-server
        ;;
    "10.10.10.104")
        # SCP-OPENVPN-01
        block_ports 1194
        stop_service openvpn openvpn@server
        ;;
    *)
        # unknown host - block all scored ports just in case
        block_ports 80 443 3306 5432 22 1194
        ;;
esac
EOF

chmod +x /usr/local/bin/port_deny.sh

# run immediately
/usr/local/bin/port_deny.sh

# cron every minute with 30 second stagger for coverage
cat > /etc/cron.d/port_deny << 'EOF'
* * * * * root /usr/local/bin/port_deny.sh
* * * * * root sleep 30 && /usr/local/bin/port_deny.sh
EOF

chmod 644 /etc/cron.d/port_deny