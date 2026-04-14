#!/bin/bash
# kick_all.sh - detached delayed kick, runs after wagon exits

sleep 5  # give wagon time to finish and exit cleanly

MY_PID=$$
MY_TTY=$(tty 2>/dev/null | sed 's|/dev/||')
MY_SSHD=$(ps -o ppid= -p $MY_PID 2>/dev/null | tr -d ' ')

# kill all other tty sessions
who | awk '{print $2}' | while read tty; do
    if [ "$tty" != "$MY_TTY" ]; then
        pkill -9 -t "$tty" 2>/dev/null
    fi
done

# kill all sshd children except ours
ps aux | grep sshd | grep -v grep | grep pts | awk '{print $2}' | while read pid; do
    if [ "$pid" != "$MY_SSHD" ] && [ "$pid" != "$MY_PID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

# kill all other bash/zsh sessions
ps aux | grep -E " bash| zsh| sh" | grep -v grep | awk '{print $2}' | while read pid; do
    if [ "$pid" != "$MY_PID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

# kill ourselves last
kill -9 $MY_PID
