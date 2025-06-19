#!/bin/bash

LOG_FILE=/home/troubleshoot/linux_server_setup.log

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting linux_server_setup.sh =====" | tee $LOG_FILE

# 必要なパッケージ
echo "$(date '+%Y-%m-%d %H:%M:%S') | Installing required packages..." | tee -a $LOG_FILE
apt-get update >> $LOG_FILE 2>&1
apt-get install -y build-essential libssl-dev libgnutls28-dev nettle-dev pkg-config perl g++ wget libdb-dev dnsmasq >> $LOG_FILE 2>&1

# ----- DNS Forwarding 環境セットアップ -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Configuring DNS forwarding..." | tee -a $LOG_FILE

# resolved.conf 更新
sed -i 's/#DNS=/DNS=8.8.8.8/g' /etc/systemd/resolved.conf
sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf

# resolv.conf 更新
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# systemd-resolved restart
systemctl restart systemd-resolved

# dnsmasq 設定ファイル作成
cat << EOF > /etc/dnsmasq.conf
server=8.8.8.8
server=8.8.4.4
listen-address=127.0.0.1,10.0.1.6
EOF

# dnsmasq 再起動
systemctl restart dnsmasq

# DNS 状態確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Listening DNS ports:" | tee -a $LOG_FILE
ss -lnup | grep 53 | tee -a $LOG_FILE

# ----- IP Forwarding / NAT(MASQUERADE) -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Enabling IP Forwarding & MASQUERADE..." | tee -a $LOG_FILE

# IP Forwarding
sysctl -w net.ipv4.ip_forward=1 >> $LOG_FILE 2>&1

# NAT (MASQUERADE)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE >> $LOG_FILE 2>&1

# ip_forward 状態確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | IP forwarding status:" | tee -a $LOG_FILE
sysctl net.ipv4.ip_forward | tee -a $LOG_FILE

# iptables 状態確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | iptables NAT table:" | tee -a $LOG_FILE
iptables -t nat -L -n -v | tee -a $LOG_FILE

# ----- Squid Proxy ビルド -----
echo "$(date '+%Y-%m-%d %H:%M:%S') | Downloading Squid 6.10..." | tee -a $LOG_FILE
cd /tmp
wget http://www.squid-cache.org/Versions/v6/squid-6.10.tar.gz >> $LOG_FILE 2>&1
tar xzf squid-6.10.tar.gz
cd squid-6.10

echo "$(date '+%Y-%m-%d %H:%M:%S') | Building Squid..." | tee -a ../$LOG_FILE
./configure --prefix=/usr/local/squid --with-gnutls --enable-ssl-crtd >> ../$LOG_FILE 2>&1
make >> ../$LOG_FILE 2>&1
make install >> ../$LOG_FILE 2>&1

# ssl_crtd 初期化
echo "$(date '+%Y-%m-%d %H:%M:%S') | Initializing ssl_crtd..." | tee -a ../$LOG_FILE
/usr/local/squid/libexec/ssl_crtd -c -s /usr/local/squid/var/lib/ssl_db >> ../$LOG_FILE 2>&1

# 証明書ディレクトリ作成 & 自己署名証明書作成
echo "$(date '+%Y-%m-%d %H:%M:%S') | Creating self-signed certificate..." | tee -a ../$LOG_FILE
mkdir -p /usr/local/squid/etc/certs
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 \
    -subj "/C=JP/ST=Tokyo/L=Minato-ku/O=MyCompany/CN=proxy.local" \
    -keyout /usr/local/squid/etc/certs/proxy.key \
    -out /usr/local/squid/etc/certs/proxy.crt >> ../$LOG_FILE 2>&1

# squid.conf 作成
echo "$(date '+%Y-%m-%d %H:%M:%S') | Generating squid.conf ..." | tee -a ../$LOG_FILE

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

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== squid.conf generated =====" | tee -a ../$LOG_FILE
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== linux_server_setup.sh completed =====" | tee -a ../$LOG_FILE
