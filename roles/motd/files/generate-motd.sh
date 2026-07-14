#!/usr/bin/env bash
# Managed by Ansible
CPU_LOAD=$(awk '{print $1}' /proc/loadavg)
MEM_USED=$(free -m | awk '/^Mem:/ { printf "%.1f%%", $3/$2*100 }')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //' || echo "unknown")

printf '\e[1;34m ###########################################################\e[0m\n'
printf '\e[1;34m #\e[0m   WELCOME TO \e[1;31m%s\e[0m\n' "$(hostname | tr '[:lower:]' '[:upper:]')"
printf '\e[1;34m #\e[0m   CPU Load: %s  |  RAM Usage: %s\n' "$CPU_LOAD" "$MEM_USED"
printf '\e[1;34m #\e[0m   Disk Use: %s   |  Uptime:    %s\n' "$DISK_USAGE" "$UPTIME"
printf '\e[1;34m ###########################################################\e[0m\n\n'
