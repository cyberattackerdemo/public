#!/bin/bash
LOG_FILE="/var/log/step1_block_dns.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step1_block_dns.sh" | tee -a $LOG_FILE

# Add block entry to dnsmasq
echo "address=/.cybereason.net/0.0.0.0" | sudo tee /etc/dnsmasq.d/block_cybereason.conf

# Restart dnsmasq
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting dnsmasq..." | tee -a $LOG_FILE
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq --no-pager | grep Active | tee -a $LOG_FILE

# Stop squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Stopping squid..." | tee -a $LOG_FILE
sudo systemctl stop squid
sudo systemctl status squid --no-pager | grep Active | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step1_block_dns.sh completed." | tee -a $LOG_FILE
