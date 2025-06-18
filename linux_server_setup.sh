#!/bin/bash

LOG_FILE="/home/troubleshoot/linux_server_setup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a $LOG_FILE
}

log "Starting setup..."

# Install packages
log "Installing required packages..."
sudo apt-get update | tee -a $LOG_FILE
sudo apt-get install -y dnsmasq tinyproxy mitmproxy dos2unix net-tools | tee -a $LOG_FILE

# Disable systemd-resolved to free port 53
log "Disabling systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Configure dnsmasq logging
log "Configuring dnsmasq logging..."
sudo mkdir -p /etc/dnsmasq.d
echo "log-queries" | sudo tee /etc/dnsmasq.d/logging.conf
echo "log-facility=/var/log/dnsmasq.log" | sudo tee -a /etc/dnsmasq.d/logging.conf

# Restart dnsmasq
log "Restarting dnsmasq..."
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq | grep Active | tee -a $LOG_FILE

# Fix tinyproxy.conf: set Port 8080
log "Configuring tinyproxy to use port 8080..."
sudo sed -i 's/^Port .*/Port 8080/' /etc/tinyproxy/tinyproxy.conf
grep -i '^Port' /etc/tinyproxy/tinyproxy.conf | tee -a $LOG_FILE

# Ensure Allow 10.0.1.0/24 is present
if ! grep -q "Allow 10.0.1.0/24" /etc/tinyproxy/tinyproxy.conf; then
    echo "Allow 10.0.1.0/24" | sudo tee -a /etc/tinyproxy/tinyproxy.conf
    log "Added Allow 10.0.1.0/24 to tinyproxy.conf"
else
    log "Allow 10.0.1.0/24 already present"
fi

# Create /var/log/tinyproxy
log "Ensuring /var/log/tinyproxy exists..."
sudo mkdir -p /var/log/tinyproxy
sudo chown tinyproxy:tinyproxy /var/log/tinyproxy

# Restart tinyproxy
log "Restarting tinyproxy..."
sudo systemctl restart tinyproxy
sudo systemctl status tinyproxy | grep Active | tee -a $LOG_FILE

# Convert scripts
log "Converting scripts to LF format..."
dos2unix /home/troubleshoot/*.sh | tee -a $LOG_FILE

# ホスト名と127.0.1.1を紐づけ
log "Fixing /etc/hosts entry for hostname..."
sudo sed -i "/^127.0.1.1/ d" /etc/hosts && echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts

log "Setup complete."
