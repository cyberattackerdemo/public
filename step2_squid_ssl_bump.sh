#!/bin/bash

LOG_FILE=/home/troubleshoot/step2_squid_ssl_bump.log
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting step2_squid_ssl_bump.sh =====" | tee $LOG_FILE

# 不正な自己署名証明書を再作成 (失効した中間証明書風でもOK)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Generating invalid SSL cert..." | tee -a $LOG_FILE
openssl req -new -newkey rsa:2048 -sha256 -days 1 -nodes -x509 \
    -subj "/C=JP/ST=Tokyo/L=Minato-ku/O=BadCompany/CN=invalid-proxy.local" \
    -keyout /usr/local/squid/etc/certs/proxy.key \
    -out /usr/local/squid/etc/certs/proxy.crt >> $LOG_FILE 2>&1

# squid 再起動
echo "$(date '+%Y-%m-%d %H:%M:%S') | Restarting squid..." | tee -a $LOG_FILE
/usr/local/squid/sbin/squid -k reconfigure
/usr/local/squid/sbin/squid -s

# 状態確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | Squid process status:" | tee -a $LOG_FILE
ps aux | grep squid | grep -v grep | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | Listening ports:" | tee -a $LOG_FILE
ss -lnpt | grep 8080 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== step2_squid_ssl_bump.sh completed =====" | tee -a $LOG_FILE

# 最後に tcpdump を自動キャプチャ (300秒)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Capturing proxy traffic (8080) with tcpdump for 300 sec..." | tee -a $LOG_FILE
timeout 300 tcpdump -i any port 8080 -w /home/troubleshoot/step2_tcpdump_proxy.pcap
echo "$(date '+%Y-%m-%d %H:%M:%S') | tcpdump capture saved: /home/troubleshoot/step2_tcpdump_proxy.pcap" | tee -a $LOG_FILE
