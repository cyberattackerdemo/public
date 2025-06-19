#!/bin/bash
LOG_FILE="/home/troubleshoot/linux_server_setup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a $LOG_FILE
}

log "Starting setup..."

# Install packages
log "Installing required packages..."
sudo apt-get update | tee -a $LOG_FILE
sudo apt-get install -y dnsmasq squid mitmproxy dos2unix net-tools | tee -a $LOG_FILE

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
sudo systemctl status dnsmasq --no-pager | grep Active | tee -a $LOG_FILE

# Configure squid
log "Configuring squid..."
sudo mkdir -p /etc/squid
sudo touch /etc/squid/block_domains.acl
sudo tee /etc/squid/squid.conf <<EOF
http_port 8080

acl blocked_domains dstdomain "/etc/squid/block_domains.acl"
http_access deny blocked_domains

http_access allow all

access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
EOF

# Restart squid
log "Restarting squid..."
sudo systemctl restart squid
sudo systemctl status squid --no-pager | grep Active | tee -a $LOG_FILE

# Convert scripts
log "Converting scripts to LF format..."
dos2unix /home/troubleshoot/*.sh | tee -a $LOG_FILE

# Hostname fix
sudo sed -i "/^127.0.1.1/ d" /etc/hosts && echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts

log "Setup complete."
