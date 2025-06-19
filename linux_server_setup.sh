#!/bin/bash

LOG_FILE="/home/troubleshoot/linux_server_setup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a $LOG_FILE
}

log "===== Starting linux_server_setup.sh ====="

# Squid 6.10 Build & Install
log "Downloading Squid 6.10..."
wget http://www.squid-cache.org/Versions/v6/squid-6.10.tar.gz -O /tmp/squid-6.10.tar.gz | tee -a $LOG_FILE

log "Extracting Squid..."
tar -xzf /tmp/squid-6.10.tar.gz -C /tmp | tee -a $LOG_FILE

log "Building Squid..."
cd /tmp/squid-6.10 && ./configure --prefix=/usr/local/squid --with-openssl | tee -a $LOG_FILE
make -j$(nproc) | tee -a $LOG_FILE
make install | tee -a $LOG_FILE

# Create squid.service
log "Creating squid.service..."
cat <<EOF | sudo tee /etc/systemd/system/squid.service
[Unit]
Description=Squid Web Proxy Server (custom build)
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/squid/sbin/squid -sY
ExecReload=/usr/local/squid/sbin/squid -k reconfigure
ExecStop=/usr/local/squid/sbin/squid -k shutdown
PIDFile=/usr/local/squid/var/run/squid.pid
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Generate SSL CA cert
log "Generating Squid SSL CA cert..."
mkdir -p /etc/squid/ssl_cert
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/CN=ProxyCA" \
    -keyout /etc/squid/ssl_cert/myCA.key -out /etc/squid/ssl_cert/myCA.pem | tee -a $LOG_FILE

# Prepare SSL cert DB
/usr/local/squid/libexec/security_file_certgen -c -s /var/lib/ssl_db -M 4MB | tee -a $LOG_FILE

# Deploy squid.conf
log "Configuring Squid..."
cat <<EOF | sudo tee /usr/local/squid/etc/squid.conf
http_port 8080 ssl-bump cert=/etc/squid/ssl_cert/myCA.pem key=/etc/squid/ssl_cert/myCA.key generate-host-certificates=on dynamic_cert_mem_cache_size=4MB

sslcrtd_program /usr/local/squid/libexec/security_file_certgen -s /var/lib/ssl_db -M 4MB

acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

http_access allow all
EOF

# Enable & start Squid
log "Enabling & starting Squid..."
sudo systemctl enable squid
sudo systemctl start squid
sudo systemctl status squid --no-pager | tee -a $LOG_FILE

# DNSMasq Setup
log "Enabling & starting dnsmasq..."
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
sudo systemctl status dnsmasq --no-pager | tee -a $LOG_FILE

# Download step1/step2/step3 scripts
log "Downloading step scripts..."
curl -L -o /home/troubleshoot/step1_block_dns.sh https://raw.githubusercontent.com/cyberattackerdemo/public/main/step1_block_dns.sh
curl -L -o /home/troubleshoot/step2_squid_ssl_bump.sh https://raw.githubusercontent.com/cyberattackerdemo/public/main/step2_squid_ssl_bump.sh
curl -L -o /home/troubleshoot/step3_restore_proxy.sh https://raw.githubusercontent.com/cyberattackerdemo/public/main/step3_restore_proxy.sh
chmod +x /home/troubleshoot/*.sh

# Convert scripts
log "Converting scripts to LF format..."
dos2unix /home/troubleshoot/*.sh | tee -a $LOG_FILE

log "===== Setup complete. ====="
