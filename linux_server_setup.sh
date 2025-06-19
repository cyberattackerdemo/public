#!/bin/bash

LOG_FILE="/home/troubleshoot/linux_server_setup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a $LOG_FILE
}

log "Starting setup..."

# Install packages
log "Installing required packages..."
sudo apt-get update | tee -a $LOG_FILE
sudo apt-get install -y squid dos2unix net-tools | tee -a $LOG_FILE

# Set squid listen port to 8080
log "Configuring squid port 8080..."
sudo sed -i 's/^http_port .*/http_port 8080/' /etc/squid/squid.conf

# Create blocked_domains.txt
sudo bash -c "echo '' > /etc/squid/blocked_domains.txt"

# Add ACL block config if not present
if ! grep -q "acl blocked_domains" /etc/squid/squid.conf; then
    echo "acl blocked_domains dstdomain \"/etc/squid/blocked_domains.txt\"" | sudo tee -a /etc/squid/squid.conf
    echo "http_access deny blocked_domains" | sudo tee -a /etc/squid/squid.conf
    echo "http_access allow all" | sudo tee -a /etc/squid/squid.conf
fi

# Restart squid
log "Restarting squid..."
sudo systemctl restart squid
sudo systemctl enable squid
sudo systemctl status squid | grep Active | tee -a $LOG_FILE

# Convert scripts
log "Converting scripts to LF format..."
dos2unix /home/troubleshoot/*.sh | tee -a $LOG_FILE

# ホスト名と127.0.1.1を紐づけ
sudo sed -i "/^127.0.1.1/ d" /etc/hosts && echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts

log "Setup complete."
