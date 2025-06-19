#!/bin/bash

LOG_FILE="/var/log/dnsmasq-step1.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step1_block_dns.sh" | sudo tee -a $LOG_FILE

# Apply block rule
echo "address=/cybereason.net/0.0.0.0" | sudo tee /etc/dnsmasq.d/block-cybereason.conf

# Restart dnsmasq
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting dnsmasq..." | sudo tee -a $LOG_FILE
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq --no-pager | grep Active | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step1_block_dns.sh completed." | sudo tee -a $LOG_FILE
