#!/bin/bash
LOG_FILE="/var/log/step3_restore_normal.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step3_restore_normal.sh" | tee -a $LOG_FILE

# Remove block dnsmasq config if exists
if [ -f /etc/dnsmasq.d/block_cybereason.conf ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Removing block_cybereason.conf" | tee -a $LOG_FILE
    sudo rm -f /etc/dnsmasq.d/block_cybereason.conf
    sudo systemctl restart dnsmasq
    sudo systemctl status dnsmasq --no-pager | grep Active | tee -a $LOG_FILE
fi

# Restart squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid..." | tee -a $LOG_FILE
sudo systemctl restart squid
sudo systemctl status squid --no-pager | grep Active | tee -a $LOG_FILE

# Kill mitmdump if running
MITMDUMP_PID=$(pgrep -f "mitmdump -p 8080")
if [ ! -z "$MITMDUMP_PID" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Stopping mitmdump (PID $MITMDUMP_PID)" | tee -a $LOG_FILE
    sudo kill "$MITMDUMP_PID"
    sleep 2
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | No mitmdump process running" | tee -a $LOG_FILE
fi

# Confirm port 8080 used by squid
sleep 2
echo "$(date '+%Y-%m-%d %H:%M:%S') | Verifying 8080 is used by squid:" | tee -a $LOG_FILE
sudo netstat -tnlp | grep 8080 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step3_restore_normal.sh completed." | tee -a $LOG_FILE
