#!/bin/bash

LOG_FILE="/var/log/step3_restore_proxy.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | sudo tee -a $LOG_FILE
}

log "===== Starting step3_restore_proxy.sh ====="

# Restart both services to initial state
log "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq --no-pager | sudo tee -a $LOG_FILE

log "Restarting squid..."
sudo systemctl restart squid
sudo systemctl status squid --no-pager | sudo tee -a $LOG_FILE

log "===== step3_restore_proxy.sh completed. ====="
