#!/bin/bash

LOG_FILE="/var/log/squid-step2.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step2_ssl_error.sh" | sudo tee -a $LOG_FILE

# Enable SSL-Bump in squid.conf (簡易例: 実運用なら証明書作成も追加）
sudo tee /etc/squid/squid.conf > /dev/null <<EOF
http_port 8080 ssl-bump cert=/etc/squid/ssl_cert/myCA.pem key=/etc/squid/ssl_cert/myCA.key
acl localnet src 10.0.1.0/24
http_access allow localnet
ssl_bump terminate all
EOF

# Restart squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid with SSL bump..." | sudo tee -a $LOG_FILE
sudo systemctl restart squid
sudo systemctl status squid --no-pager | grep Active | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step2_ssl_error.sh completed." | sudo tee -a $LOG_FILE
