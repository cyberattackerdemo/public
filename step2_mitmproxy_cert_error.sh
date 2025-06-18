#!/bin/bash

echo "Removing DNS override for example.com..."
sudo rm -f /etc/dnsmasq.d/block-example.conf
sudo systemctl restart dnsmasq

echo "Stopping tinyproxy..."
sudo systemctl stop tinyproxy

echo "Starting mitmproxy with logging..."
LOGFILE=~/mitmproxy.log

# 過去のログを退避
[ -f "$LOGFILE" ] && mv "$LOGFILE" "${LOGFILE}.$(date +%Y%m%d_%H%M%S)"

# mitmproxy をバックグラウンドで起動し、ログを保存
nohup mitmproxy --mode regular --listen-port 8080 \
  --set console_eventlog_verbosity=info >> "$LOGFILE" 2>&1 &

sleep 2
pgrep mitmproxy > /dev/null && echo "mitmproxy is running. Logging to $LOGFILE" || echo "mitmproxy failed to start"
