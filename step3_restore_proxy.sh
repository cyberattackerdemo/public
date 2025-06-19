#!/bin/bash

# step3_normal_proxy.sh
# Purpose: Switch squid to normal proxy (no MITM), allow HTTPS to succeed
# Date: 2025-06-19

LOG_FILE="/var/log/step3_normal_proxy.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step3_normal_proxy.sh" | sudo tee -a $LOG_FILE

# dnsmasq active 確認（そのまま）
sudo systemctl status dnsmasq --no-pager | sudo tee -a $LOG_FILE

# Reconfigure Squid.conf (no SSL-Bump, port 8080 normal)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Reconfiguring squid to normal proxy..." | sudo tee -a $LOG_FILE

sudo tee /etc/squid/squid.conf <<EOF
http_port 8080

acl localnet src 10.0.1.0/24

http_access allow localnet
http_access deny all

cache deny all
EOF

# Restart squid (normal mode)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting Squid (normal mode)..." | sudo tee -a $LOG_FILE
sudo systemctl restart squid
sleep 3

# 状態確認
sudo systemctl status squid --no-pager | sudo tee -a $LOG_FILE

# lsof ポート確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Ports in use:" | sudo tee -a $LOG_FILE
sudo lsof -i :53 | sudo tee -a $LOG_FILE
sudo lsof -i :8080 | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step3_normal_proxy.sh completed." | sudo tee -a $LOG_FILE
