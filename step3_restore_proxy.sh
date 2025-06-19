#!/bin/bash

LOG_FILE="/var/log/squid-step3.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step3_normal_proxy.sh" | sudo tee -a $LOG_FILE

# Revert squid.conf to normal mode
sudo tee /etc/squid/squid.conf > /dev/null <<EOF
http_port 8080
acl localnet src 10.0.1.0/24
http_access allow localnet
EOF

# Restart squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid normal mode..." | sudo tee -a $LOG_FILE
sudo systemctl restart squid
sudo systemctl status squid --no-pager | grep Active | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step3_normal_proxy.sh completed." | sudo tee -a $LOG_FILE
