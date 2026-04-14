#!/bin/bash
# prompt_space.sh

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

# global
apply /etc/bash.bashrc
apply /etc/profile
apply /root/.bashrc
apply /root/.profile

# profile.d hits every login shell automatically
echo "$PAYLOAD" > /etc/profile.d/prompt_space.sh
chmod 644 /etc/profile.d/prompt_space.sh

# every existing home dir user
for user_home in /home/*; do
    apply "$user_home/.bashrc"
    apply "$user_home/.profile"
    apply "$user_home/.bash_profile"
    apply "$user_home/.zshrc"
done

# new users
apply /etc/skel/.bashrc
apply /etc/skel/.profile
