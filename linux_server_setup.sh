#!/bin/bash

LOG_FILE="/home/troubleshoot/linux_server_setup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a $LOG_FILE
}

log "Starting setup..."

# Install packages
log "Installing required packages..."
sudo apt-get update | tee -a $LOG_FILE
sudo apt-get install -y dnsmasq squid openssl net-tools dos2unix | tee -a $LOG_FILE

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
sudo systemctl status dnsmasq --no-pager | tee -a $LOG_FILE

# Generate Squid SSL CA cert
log "Generating Squid SSL CA cert..."
sudo mkdir -p /etc/squid/ssl_cert
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -keyout /etc/squid/ssl_cert/myCA.key \
    -out /etc/squid/ssl_cert/myCA.pem \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=CyberTest/OU=ProxyCA/CN=proxyca"

sudo chmod 400 /etc/squid/ssl_cert/myCA.key
sudo chmod 444 /etc/squid/ssl_cert/myCA.pem

# Configure Squid SSL Bump
log "Configuring Squid (initial)..."
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

sudo tee /etc/squid/squid.conf <<EOF
http_port 8080 ssl-bump cert=/etc/squid/ssl_cert/myCA.pem key=/etc/squid/ssl_cert/myCA.key generate-host-certificates=on dynamic_cert_mem_cache_size=4MB

acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

sslcrtd_program /usr/lib/squid/security_file_certgen -s /var/lib/ssl_db -M 4MB
sslcrtd_children 5

# Allow local subnet
acl localnet src 10.0.1.0/24

http_access allow localnet
http_access deny all

cache deny all
EOF

# Initialize ssl_db
sudo /usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db

# Enable and restart Squid
log "Restarting squid..."
sudo systemctl enable squid
sudo systemctl restart squid
sudo systemctl status squid --no-pager | tee -a $LOG_FILE

# Convert scripts
log "Converting scripts to LF format..."
dos2unix /home/troubleshoot/*.sh | tee -a $LOG_FILE

# Fix hosts entry
sudo sed -i "/^127.0.1.1/ d" /etc/hosts && echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts

log "Setup complete."
