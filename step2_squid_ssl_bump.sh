#!/bin/bash

LOG_FILE="/var/log/step2_squid_ssl_bump.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | sudo tee -a $LOG_FILE
}

log "===== Starting step2_squid_ssl_bump.sh ====="

# Stop dnsmasq (optional)
log "Stopping dnsmasq..."
sudo systemctl stop dnsmasq
sudo systemctl status dnsmasq --no-pager | sudo tee -a $LOG_FILE

# Start Squid with SSL Bump
log "Starting squid (SSL bump)..."
sudo systemctl restart squid
sudo systemctl status squid --no-pager | sudo tee -a $LOG_FILE

log "===== step2_squid_ssl_bump.sh completed. ====="
