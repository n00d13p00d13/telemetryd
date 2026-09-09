#!/bin/bash

set -euo pipefail

eval "$(ssh-agent -s)"
trap 'kill "$SSH_AGENT_PID"' EXIT

HOST_ADDR="root@192.168.1.113"
TEMPLATE_ID=102

TEMPLATE_USER="debtesttemplate" 

execute_host() {
    local cmd="$1"
    ssh "$HOST_ADDR" "$cmd"
}

get_vm_ip() {
    local vmid="$1"
    local vm_ip=""

    # poll until the guest agent reports a valid 192.168.1.x ip
    while [[ -z "$vm_ip" ]]; do
        vm_ip=$(execute_host "qm agent $vmid network-get-interfaces 2>/dev/null" | \
            jq -r '.[]["ip-addresses"][]? | select(.["ip-address-type"] == "ipv4" and (.["ip-address"] | startswith("192.168.1."))) | .["ip-address"]' 2>/dev/null | head -n1)
        
        if [[ -z "$vm_ip" ]]; then
            sleep 2
        fi
    done

    echo "$vm_ip"
}

###########

ssh-add ~/.ssh/id_rsa

declare -a new_id
for i in {1..3}; do
    new_id[$i]=$((TEMPLATE_ID + i))
    
    execute_host "qm clone $TEMPLATE_ID ${new_id[$i]} --name \"debtest-$i\" --full 1"
    execute_host "qm set ${new_id[$i]} --cores 2 --memory 2048"
    execute_host "qm start ${new_id[$i]}"
done

started=0
while [[ $started != 3 ]]; do
    started=$(execute_host "qm list" | awk -v tid="$TEMPLATE_ID" -v num=3 '
        $1 > tid && $1 <= (tid + num) && $3 == "running" { count++ }
        END { print count+0 }
    ')
    sleep 2
done

echo "VMs are powered on"

# deploying the telemetry daemon
for i in {1..3}; do
    ip_address=$(get_vm_ip "${new_id[$i]}")
    
    ssh_target="${TEMPLATE_USER}@${ip_address}"
    echo "VM ${new_id[$i]} acquired IP: $ip_address"

    scp -o StrictHostKeyChecking=no telemetryd.sh telemetryd.service telemetryd.nginx ${ssh_target}:/tmp
    
    ssh -o StrictHostKeyChecking=no "$ssh_target" 'set -euo pipefail
    sudo apt update && sudo apt install -y nginx jq 

    sudo mv /tmp/telemetryd.sh /usr/local/bin/telemetryd.sh 
    sudo chmod +x /usr/local/bin/telemetryd.sh 

    sudo mv /tmp/telemetryd.service /etc/systemd/system/telemetryd.service 
    sudo mkdir -p /var/www/telemetry 
    sudo chown -R www-data:www-data /var/www/telemetry 

    sudo mv /tmp/telemetryd.nginx /etc/nginx/sites-available/telemetry 
    sudo ln -sf /etc/nginx/sites-available/telemetry /etc/nginx/sites-enabled/default 

    sudo systemctl daemon-reload 
    sudo systemctl enable --now telemetryd.service 
    sudo systemctl reload nginx'

    echo "VM ${new_id[$i]} successfully deployed."
done
