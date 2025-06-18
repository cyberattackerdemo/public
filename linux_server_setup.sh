#!/bin/bash

# ログファイル
LOG_FILE="/home/troubleshoot/linux_server_setup.log"

# ログ出力関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a $LOG_FILE
}

log "Starting setup..."

# パッケージインストール
log "Installing required packages..."
sudo apt-get update | tee -a $LOG_FILE
sudo apt-get install -y dnsmasq tinyproxy mitmproxy dos2unix | tee -a $LOG_FILE

# dnsmasq logging
log "Configuring dnsmasq logging..."
sudo mkdir -p /etc/dnsmasq.d
echo "log-queries" | sudo tee /etc/dnsmasq.d/logging.conf
echo "log-facility=/var/log/dnsmasq.log" | sudo tee -a /etc/dnsmasq.d/logging.conf

# dnsmasq restart
log "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq | grep Active | tee -a $LOG_FILE

# tinyproxy restart
log "Restarting tinyproxy..."
sudo systemctl restart tinyproxy
sudo systemctl status tinyproxy | grep Active | tee -a $LOG_FILE

log "Setup complete."
