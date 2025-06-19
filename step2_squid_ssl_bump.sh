#!/bin/bash

# step2_cert_error.sh
# Purpose: Switch proxy to Squid (MITM) and trigger cert error
# Date: 2025-06-19

LOG_FILE="/var/log/step2_cert_error.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step2_cert_error.sh" | sudo tee -a $LOG_FILE

# dnsmasq active 確認（そのまま）
sudo systemctl status dnsmasq --no-pager | sudo tee -a $LOG_FILE

# Restart Squid (MITM enabled)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting Squid (MITM mode)..." | sudo tee -a $LOG_FILE
sudo systemctl restart squid
sleep 3

# Squid 状態確認
sudo systemctl status squid --no-pager | sudo tee -a $LOG_FILE

# lsof でポート確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Ports in use:" | sudo tee -a $LOG_FILE
sudo lsof -i :53 | sudo tee -a $LOG_FILE
sudo lsof -i :8080 | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step2_cert_error.sh completed." | sudo tee -a $LOG_FILE
