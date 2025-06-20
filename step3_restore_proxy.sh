#!/bin/bash

LOG_FILE=/home/troubleshoot/step3_restore_proxy.log
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting step3_restore_proxy.sh =====" | tee $LOG_FILE

# dnsmasq block 設定 削除
echo "$(date '+%Y-%m-%d %H:%M:%S') | Removing dnsmasq block config..." | tee -a $LOG_FILE
rm -f /etc/dnsmasq.d/block_cybereason.conf

# dnsmasq 再起動
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting dnsmasq..." | tee -a $LOG_FILE
systemctl restart dnsmasq

# DNS unblock 確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | dig cybereason.net after unblock:" | tee -a $LOG_FILE
dig cybereason.net @127.0.0.1 | tee -a $LOG_FILE

# 正常な proxy 証明書を作り直す
echo "$(date '+%Y-%m-%d %H:%M:%S') | Re-generating valid SSL cert..." | tee -a $LOG_FILE
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 \
    -subj "/C=JP/ST=Tokyo/L=Minato-ku/O=MyCompany/CN=proxy.local" \
    -keyout /usr/local/squid/etc/certs/proxy.key \
    -out /usr/local/squid/etc/certs/proxy.crt >> $LOG_FILE 2>&1

# squid 再起動
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid..." | tee -a $LOG_FILE
/usr/local/squid/sbin/squid -k reconfigure
/usr/local/squid/sbin/squid -s

# プロセス確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Squid process status:" | tee -a $LOG_FILE
ps aux | grep squid | grep -v grep | tee -a $LOG_FILE

# Listenポート確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Listening ports:" | tee -a $LOG_FILE
ss -lnpt | grep 8080 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== step3_restore_proxy.sh completed =====" | tee -a $LOG_FILE

# Proxyキャプチャ
echo "$(date '+%Y-%m-%d %H:%M:%S') | Capturing proxy traffic (8080) with tcpdump for 300 sec..." | tee -a $LOG_FILE
sudo timeout 300 tcpdump -nnvvXS -i any port 8080 | tee /home/troubleshoot/step3_tcpdump_proxy.txt
echo "$(date '+%Y-%m-%d %H:%M:%S') | tcpdump proxy capture saved: /home/troubleshoot/step3_tcpdump_proxy.pcap" | tee -a $LOG_FILE
