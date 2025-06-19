#!/bin/bash

# step1_block_dns.sh
# Purpose: Block .cybereason.net name resolution using dnsmasq (stop squid)
# Date: 2025-06-19

LOG_FILE="/var/log/step1_block_dns.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step1_block_dns.sh" | sudo tee -a $LOG_FILE

# stop squid (必須)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Stopping squid..." | sudo tee -a $LOG_FILE
sudo systemctl stop squid
sudo systemctl status squid --no-pager | grep Active | sudo tee -a $LOG_FILE

# Write block rule to dnsmasq
echo "$(date '+%Y-%m-%d %H:%M:%S') | Writing block rule for .cybereason.net to dnsmasq..." | sudo tee -a $LOG_FILE
echo "address=/.cybereason.net/0.0.0.0" | sudo tee /etc/dnsmasq.d/block_cybereason.conf

# Restart dnsmasq
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting dnsmasq..." | sudo tee -a $LOG_FILE
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq --no-pager | grep Active | sudo tee -a $LOG_FILE

# Show active services
echo "$(date '+%Y-%m-%d %H:%M:%S') | Current service states:" | sudo tee -a $LOG_FILE
echo "--- dnsmasq ---" | sudo tee -a $LOG_FILE
sudo systemctl status dnsmasq --no-pager | grep Active | sudo tee -a $LOG_FILE
echo "--- squid ---" | sudo tee -a $LOG_FILE
sudo systemctl status squid --no-pager | grep Active | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step1_block_dns.sh completed." | sudo tee -a $LOG_FILE
