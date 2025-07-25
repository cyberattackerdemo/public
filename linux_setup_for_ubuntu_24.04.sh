#!/bin/bash

LOG_FILE=/home/troubleshoot/linux_server_setup.log

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting linux_server_setup.sh =====" | tee $LOG_FILE

# 必要なパッケージ
echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing required packages..." | tee -a $LOG_FILE
apt-get update >> $LOG_FILE 2>&1
apt-get install -y build-essential libssl-dev pkg-config perl g++ wget libdb-dev dnsmasq libxml2-dev libexpat1-dev >> $LOG_FILE 2>&1

# ----- DNS Forwarding 環境セットアップ -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Configuring DNS forwarding..." | tee -a $LOG_FILE
sed -i 's/#DNS=/DNS=8.8.8.8/g' /etc/systemd/resolved.conf
sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

cat << EOF > /etc/dnsmasq.conf
server=8.8.8.8
server=8.8.4.4
listen-address=127.0.0.1,10.0.1.6
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq

echo "$(date '+%Y-%m-%d %H:%M:%S') | Listening DNS ports:" | tee -a $LOG_FILE
ss -lnup | grep 53 | tee -a $LOG_FILE

# ----- Squid Proxy ビルド -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Downloading Squid 6.10..." | tee -a $LOG_FILE
cd /tmp
wget http://www.squid-cache.org/Versions/v6/squid-6.10.tar.gz >> $LOG_FILE 2>&1
tar xzf squid-6.10.tar.gz
cd squid-6.10

echo "$(date '+%Y-%m-%d %H:%M:%S') | Building Squid..." | tee -a $LOG_FILE
./configure --prefix=/usr/local/squid --with-openssl --enable-ssl-crtd >> $LOG_FILE 2>&1
make -j$(nproc) >> $LOG_FILE 2>&1
make install >> $LOG_FILE 2>&1

# ssl_crtd 存在確認
if [ ! -x /usr/local/squid/libexec/ssl_crtd ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ERROR: ssl_crtd not found!!" | tee -a $LOG_FILE
fi

# ssl_db 初期化
echo "$(date '+%Y-%m-%d %H:%M:%S') | Initializing ssl_crtd..." | tee -a $LOG_FILE
mkdir -p /usr/local/squid/var/lib/ssl_db
chown nobody:nogroup /usr/local/squid/var/lib/ssl_db
/usr/local/squid/libexec/ssl_crtd -c -s /usr/local/squid/var/lib/ssl_db >> $LOG_FILE 2>&1

# 証明書ディレクトリ作成 & 自己署名証明書作成
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating self-signed certificate..." | tee -a $LOG_FILE
mkdir -p /usr/local/squid/etc/certs
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 \
    -subj "/C=JP/ST=Tokyo/L=Minato-ku/O=MyCompany/CN=proxy.local" \
    -keyout /usr/local/squid/etc/certs/proxy.key \
    -out /usr/local/squid/etc/certs/proxy.crt >> $LOG_FILE 2>&1

# squid.conf 作成
echo "$(date '+%Y-%m-%d %H:%M:%S') | Generating squid.conf ..." | tee -a $LOG_FILE
cat << EOF > /usr/local/squid/etc/squid.conf
# Squid Proxy Configuration

# HTTP Proxy port
http_port 8080 ssl-bump cert=/usr/local/squid/etc/certs/proxy.crt key=/usr/local/squid/etc/certs/proxy.key

# SSL Bump configuration
acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

# SSL Certificate Database
sslcrtd_program /usr/local/squid/libexec/ssl_crtd -s /usr/local/squid/var/lib/ssl_db -M 4MB
sslcrtd_children 5

# ACL
acl localnet src 10.0.0.0/8
http_access allow localnet
http_access deny all

# Logging
access_log stdio:/usr/local/squid/var/logs/access.log
EOF

# ----- squid 動作用ディレクトリ作成 & 権限補正 -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating squid runtime directories ..." | tee -a $LOG_FILE
mkdir -p /usr/local/squid/var/run
mkdir -p /usr/local/squid/var/logs
chown -R nobody:nogroup /usr/local/squid/var/run
chown -R nobody:nogroup /usr/local/squid/var/logs

# ----- Squid systemd service 作成 -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating squid.service ..." | tee -a $LOG_FILE
cat << EOF > /etc/systemd/system/squid.service
[Unit]
Description=Squid Web Proxy
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/squid/sbin/squid -s
ExecReload=/usr/local/squid/sbin/squid -k reconfigure
ExecStop=/usr/local/squid/sbin/squid -k shutdown
PIDFile=/usr/local/squid/var/run/squid.pid
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# systemctl reload & enable & start squid
systemctl daemon-reload
systemctl enable squid
systemctl start squid

# ----- /dev/shm cleanup -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Cleaning /dev/shm for squid ..." | tee -a $LOG_FILE
rm -f /dev/shm/squid-*.shm

# Squid 状態確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Squid status:" | tee -a $LOG_FILE
systemctl status squid --no-pager | tee -a $LOG_FILE

# Squid ポート確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Squid Listening ports:" | tee -a $LOG_FILE
ss -lnpt | grep 8080 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== squid.conf generated =====" | tee -a $LOG_FILE
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== linux_server_setup.sh completed =====" | tee -a $LOG_FILE
