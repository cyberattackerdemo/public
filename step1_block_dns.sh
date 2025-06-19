#!/bin/bash

LOG_FILE="/var/log/step1_block_dns.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | sudo tee -a $LOG_FILE
}

log "===== Starting step1_block_dns.sh ====="

# dnsmasq block list
sudo tee /etc/dnsmasq.d/blocklist.conf > /dev/null <<EOF
address=/.cybereason.net/0.0.0.0
EOF

# Restart dnsmasq
log "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq --no-pager | sudo tee -a $LOG_FILE

# Stop Squid
log "Stopping squid..."
sudo systemctl stop squid
sudo systemctl status squid --no-pager | sudo tee -a $LOG_FILE

log "===== step1_block_dns.sh completed. ====="
