#!/bin/bash

set -euo pipefail

LOG_FILE="/var/www/telemetry/metrics.json"
TMP_FILE="${LOG_FILE}tmp"
mkdir -p "$(dirname "$LOG_FILE")"

INTERVAL=${1:-1}

trap 'echo "$(date): Telemetryd Daemon exiting gracefully..."; exit 0' SIGTERM SIGINT

echo "$(date): Telemetryd Daemon started."

read_cpu_stats() { 
    cat /proc/stat | awk '/^cpu/ && NR < 2 { print ($2 + $3 + $4 + $5), $5 }'
}

while true; do
    cpu_t1=$(awk '/^cpu / {print ($2+$3+$4+$5+$6+$7+$8+$9+$10), $5, $9}' /proc/stat)
    disk_t1=$(awk '/ (vda|sda) / {print $6, $10; exit}' /proc/diskstats)
    net_t1=$(awk '/(eth0|ens18|enp)/ {print $2, $4, $5, $10, $12, $13; exit}' /proc/net/dev)

    sleep "$INTERVAL"

    cpu_t2=$(awk '/^cpu / {print ($2+$3+$4+$5+$6+$7+$8+$9+$10), $5, $9}' /proc/stat)
    disk_t2=$(awk '/ (vda|sda) / {print $6, $10; exit}' /proc/diskstats)
    net_t2=$(awk '/(eth0|ens18|enp)/ {print $2, $4, $5, $10, $12, $13; exit}' /proc/net/dev)

    read -r load_1 load_5 load_15 _ < /proc/loadavg
    
    mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    mem_dirty=$(awk '/^Dirty:/ {print $2}' /proc/meminfo)

    # CALCULATE DELTAS
    
    read -r c1_total c1_idle c1_steal <<< "$cpu_t1"
    read -r c2_total c2_idle c2_steal <<< "$cpu_t2"
    
    d_total=$(( c2_total - c1_total ))
    d_idle=$(( c2_idle - c1_idle ))
    d_steal=$(( c2_steal - c1_steal ))

    if [[ $d_total -gt 0 ]]; then
        cpu_util=$(( 100 * (d_total - d_idle) / d_total ))
        cpu_steal=$(( 100 * d_steal / d_total ))
    else
        cpu_util=0; cpu_steal=0
    fi

    if [[ -n "$disk_t1" && -n "$disk_t2" ]]; then
        read -r d1_read d1_write <<< "$disk_t1"
        read -r d2_read d2_write <<< "$disk_t2"
        disk_read_bps=$(( (d2_read - d1_read) * 512 / INTERVAL ))
        disk_write_bps=$(( (d2_write - d1_write) * 512 / INTERVAL ))
    else
        disk_read_bps=0; disk_write_bps=0
    fi

    if [[ -n "$net_t1" && -n "$net_t2" ]]; then
        read -r rx1_b rx1_e rx1_d tx1_b tx1_e tx1_d <<< "$net_t1"
        read -r rx2_b rx2_e rx2_d tx2_b tx2_e tx2_d <<< "$net_t2"
        
        net_rx_bps=$(( (rx2_b - rx1_b) / INTERVAL ))
        net_tx_bps=$(( (tx2_b - tx1_b) / INTERVAL ))
        net_drops=$(( (rx2_d - rx1_d) + (tx2_d - tx1_d) ))
        net_errs=$(( (rx2_e - rx1_e) + (tx2_e - tx1_e) ))
    else
        net_rx_bps=0; net_tx_bps=0; net_drops=0; net_errs=0
    fi

    # write to a temp file first, then use mv to overwrite to a single file.
    
    cat <<EOF > "$TMP_FILE"
{
  "system": {
    "load_1m": $load_1,
    "load_5m": $load_5,
    "load_15m": $load_15
  },
  "cpu": {
    "utilization_pct": $cpu_util,
    "steal_pct": $cpu_steal
  },
  "memory": {
    "total_kb": $mem_total,
    "available_kb": $mem_avail,
    "dirty_kb": $mem_dirty
  },
  "disk": {
    "read_bytes_per_sec": $disk_read_bps,
    "write_bytes_per_sec": $disk_write_bps
  },
  "network": {
    "rx_bytes_per_sec": $net_rx_bps,
    "tx_bytes_per_sec": $net_tx_bps,
    "drops": $net_drops,
    "errors": $net_errs
  }
}
EOF

    mv "$TMP_FILE" "$LOG_FILE"

done
