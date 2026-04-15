#!/bin/bash

# ==========================================
# Description: Disconnects all active SSH sessions gracefully or forcefully
# ==========================================

# Configuration
MASTER_PPID=""          # The parent PID of the master sshd process
ALL_PIDS=()              # Array to store all relevant PIDs
CONFIRM=1                # Set to 0 to skip user confirmation
KILL_TYPE="HUP"          # "HUP" (Graceful) or "9" (Force)

echo "========================================="
echo "SSH Session Disconnection Tool"
echo "Targeting master process..."
echo "========================================="

# 1. Find the Master sshd Process (PID 1 of the sshd tree)
MASTER_PID=$(pgrep -f 'sshd')

# If no sshd found, exit early
if [ -z "$MASTER_PID" ]; then
    echo "No active SSH Master process found."
    exit 0
fi

# 2. Find all child sessions and the master
# -p specifies the PID of the master
# -o pid= shows only the PID for clean iteration
ALL_PIDS=($(ps -o pid= -p "$MASTER_PID" 2>/dev/null | sort -u | tr '\n' ' '))

# 3. Optional: Display current sessions
echo ""
echo "Found SSH sessions (Parent + Children):"
echo "-------------------------------------------"
for pid in ${ALL_PIDS[@]}; do
    user=$(ps -p "$pid" -o user= 2>/dev/null)
    cmd=$(ps -p "$pid" -o args= 2>/dev/null | head -1)
    echo "PID: $pid | User: $user | Command: $cmd"
done

# 4. Check if user wants to proceed
if [ "$CONFIRM" -eq 1 ]; then
    read -p "Proceed to kill all sessions? [y/N] " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# 5. Kill the sessions
echo "Killing sessions..."
# -s SIGTERM is graceful (HUP equivalent). -9 is force.
# Using kill -s <SIG> -pid works like kill -9
for pid in ${ALL_PIDS[@]}; do
    if kill -s "$KILL_TYPE" -p "$pid" 2>/dev/null; then
        echo "  - Killed PID: $pid"
    fi
done

echo ""
echo "Verifying processes..."
sleep 30

# Check if any remaining threads are running for sshd
remaining=$(pgrep -f 'sshd' | wc -l)
if [ "$remaining" -eq 0 ]; then
    echo "All SSH sessions have been disconnected."
    exit 0
else
    echo " $remaining sessions may still be active."
    echo "Trying force kill on remaining..."
    kill -9 $(pgrep -f 'sshd') 2>/dev/null
    echo "Final status check:"
    pgrep -f 'sshd' || echo "All clean."
    exit 0
fi