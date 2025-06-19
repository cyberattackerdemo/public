#!/bin/bash

LOG_FILE=phase1.log

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting phase1.sh =====" | tee $LOG_FILE

# Stop Squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Stopping Squid..." | tee -a $LOG_FILE
pkill squid
sleep 3

echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking if Squid is stopped (ps aux | grep squid)..." | tee -a $LOG_FILE
ps aux | grep squid | grep -v grep | tee -a $LOG_FILE

# Update squid.conf for step1
echo "$(date '+%Y-%m-%d %H:%M:%S') | Updating squid.conf for step1 ..." | tee -a $LOG_FILE

cat << EOF > /usr/local/squid/etc/squid.conf
# Squid Proxy - Step 1

http_port 8080 ssl-bump cert=/usr/local/squid/etc/certs/proxy.crt key=/usr/local/squid/etc/certs/proxy.key

acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

sslcrtd_program /usr/local/squid/libexec/ssl_crtd -s /usr/local/squid/var/lib/ssl_db -M 4MB
sslcrtd_children 5

acl localnet src 10.0.0.0/8
http_access allow localnet
http_access deny all

access_log stdio:/usr/local/squid/var/logs/access.log
EOF

# Start Squid
echo "$(date '+%Y-%m-%d %H:%M:%S') | Starting Squid with updated config..." | tee -a $LOG_FILE
/usr/local/squid/sbin/squid

sleep 3
echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking if Squid is running (ps aux | grep squid)..." | tee -a $LOG_FILE
ps aux | grep squid | grep -v grep | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== phase1.sh completed =====" | tee -a $LOG_FILE
