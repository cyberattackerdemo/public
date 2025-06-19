#!/bin/bash
LOG_FILE="/var/log/step2_mitmdump_cert_error.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step2_mitmdump_cert_error.sh" | tee -a $LOG_FILE

# Remove block dnsmasq config
sudo rm -f /etc/dnsmasq.d/block_cybereason.conf

# Restart dnsmasq
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting dnsmasq..." | tee -a $LOG_FILE
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq --no-pager | grep Active | tee -a $LOG_FILE

# Restart squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid..." | tee -a $LOG_FILE
sudo systemctl restart squid
sudo systemctl status squid --no-pager | grep Active | tee -a $LOG_FILE

# mitmdump 起動 (バックグラウンド)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Launching mitmdump..." | tee -a $LOG_FILE
nohup mitmdump -p 8080 --ssl-insecure --mode regular -w /home/troubleshoot/mitmdump.log > /dev/null 2>&1 &

sleep 3

# mitmdump プロセス確認
ps aux | grep mitmdump | grep -v grep | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step2_mitmdump_cert_error.sh completed." | tee -a $LOG_FILE
