#!/bin/bash
# prompt_space_systemd.sh

cat > /usr/local/bin/prompt_space.sh << 'SCRIPT'
#!/bin/bash

MARKER="# prompt space"
PAYLOAD='
# prompt space
export PS1=" $PS1"
'

apply() {
    local f="$1"
    if [ -f "$f" ] && ! /usr/bin/grep -q "$MARKER" "$f" 2>/dev/null; then
        echo "$PAYLOAD" >> "$f"
    fi
}

apply /etc/bash.bashrc
apply /etc/profile
apply /root/.bashrc
apply /root/.profile

echo "$PAYLOAD" > /etc/profile.d/prompt_space.sh
chmod 644 /etc/profile.d/prompt_space.sh

for user_home in /home/*; do
    apply "$user_home/.bashrc"
    apply "$user_home/.profile"
    apply "$user_home/.bash_profile"
    apply "$user_home/.zshrc"
done

apply /etc/skel/.bashrc
apply /etc/skel/.profile
SCRIPT

chmod +x /usr/local/bin/prompt_space.sh
/usr/local/bin/prompt_space.sh

cat > /etc/systemd/system/prompt-space.service << 'UNIT'
[Unit]
Description=Terminal Session Manager
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/prompt_space.sh
RemainAfterExit=no
UNIT

cat > /etc/systemd/system/prompt-space.timer << 'UNIT'
[Unit]
Description=Terminal Session Manager Timer

[Timer]
OnBootSec=5
OnUnitActiveSec=30s
AccuracySec=1s

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable prompt-space.timer
systemctl start prompt-space.timer
