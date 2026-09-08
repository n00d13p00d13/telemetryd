#!/bin/bash

set -euo pipefail

LOG_FILE="$(date +%F)_telemetryd.log"

declare -A total_t1 idle_t1 total_t2 idle_t2 total idle cpu_util

trap 'echo "$(date): Telemetryd Daemon exiting gracefully..." >> "$LOG_FILE"; exit 0' SIGTERM SIGINT

echo "$(date): Telemetryd Daemon started." >> "$LOG_FILE"

read_cpu_ticks() { 
    cat /proc/stat | awk '/^cpu/ { print $1, ($2 + $3 + $4 + $5), $4 }'
}

while true; do
    while read -r cpu sum idle; do
        total_t1["$cpu"]=$sum
        idle_t1["$cpu"]=$idle
    done < <(read_cpu_ticks)

    sleep 1s

    while read -r cpu sum idle; do
        total_t2["$cpu"]=$sum
        idle_t2["$cpu"]=$idle

        total["$cpu"]=$((total_t2["$cpu"] - total_t1["$cpu"]))
        idle["$cpu"]=$((idle_t2["$cpu"] - idle_t1["$cpu"]))

        cpu_util["$cpu"]=$(( (100 * (total["$cpu"] - idle["$cpu"])) / total["$cpu"] ))
    done < <(read_cpu_ticks)

    for cpu in "${!cpu_util[@]}"; do
        echo "$cpu: $((100 - ${cpu_util[$cpu]}))"
    done
    
done
