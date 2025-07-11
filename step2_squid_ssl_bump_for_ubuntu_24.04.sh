#!/bin/bash

LOG_FILE=/home/troubleshoot/step2_squid_ssl_bump_for_ubuntu_24.04.log
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting step2_squid_ssl_bump_for_ubuntu_24.04.sh =====" | tee $LOG_FILE

# 不正な自己署名証明書を再作成
echo "$(date '+%Y-%m-%d %H:%M:%S') | Generating invalid SSL cert..." | tee -a $LOG_FILE
openssl req -new -newkey rsa:2048 -sha256 -days 1 -nodes -x509 \
    -subj "/C=JP/ST=Tokyo/L=Minato-ku/O=BadCompany/CN=invalid-proxy.local" \
    -keyout /usr/local/squid/etc/certs/proxy.key \
    -out /usr/local/squid/etc/certs/proxy.crt >> $LOG_FILE 2>&1

# squid 再起動
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid (reconfigure + start) ..." | tee -a $LOG_FILE
/usr/local/squid/sbin/squid -k reconfigure
sleep 1
/usr/local/squid/sbin/squid -s

# 状態確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Squid process status:" | tee -a $LOG_FILE
ps aux | grep squid | grep -v grep | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | Listening ports:" | tee -a $LOG_FILE
ss -lnpt | grep 8080 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== step2_squid_ssl_bump_for_ubuntu_24.04.sh completed =====" | tee -a $LOG_FILE

# tcpdump (DNS + Proxy)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Capturing proxy (8080) and DNS (53) traffic with tcpdump for 300 sec..." | tee -a $LOG_FILE
sudo timeout 300 tcpdump -nnvvXS -i any "port 53 or port 8080" | tee /home/troubleshoot/step2_tcpdump_dns_and_proxy_for_ubuntu_24.04.txt
echo "$(date '+%Y-%m-%d %H:%M:%S') | tcpdump capture saved: /home/troubleshoot/step2_tcpdump_dns_and_proxy_for_ubuntu_24.04.txt" | tee -a $LOG_FILE
