#!/bin/bash

# step2_mitmproxy_cert_error.sh
# Purpose: Switch proxy to mitmdump and generate cert error
# Date: 2025-06-18

LOG_FILE="/var/log/mitmdump-switch.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting step2_mitmproxy_cert_error.sh" | sudo tee -a $LOG_FILE

# tinyproxy 停止
echo "$(date '+%Y-%m-%d %H:%M:%S') | Stopping tinyproxy..." | sudo tee -a $LOG_FILE
sudo systemctl stop tinyproxy

# tinyproxy 状態確認
sudo systemctl status tinyproxy --no-pager | sudo tee -a $LOG_FILE

# 少し待つ（port解放待ち）
sleep 2

# mitmdump 起動 (バックグラウンド)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Launching mitmdump on port 8080..." | sudo tee -a $LOG_FILE
nohup mitmdump -p 8080 --ssl-insecure --mode regular -w /home/troubleshoot/mitmproxy.log > /dev/null 2>&1 &

# 起動確認のため sleep
sleep 3

# mitmdump プロセス確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Current mitmdump process:" | sudo tee -a $LOG_FILE
ps aux | grep mitmdump | grep -v grep | sudo tee -a $LOG_FILE

# ポート確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Listening on port 8080:" | sudo tee -a $LOG_FILE
sudo ss -tnlp | grep 8080 | sudo tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | step2_mitmproxy_cert_error.sh completed." | sudo tee -a $LOG_FILE
