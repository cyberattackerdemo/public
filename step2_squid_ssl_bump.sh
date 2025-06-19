#!/bin/bash

LOG_FILE=/home/troubleshoot/step2_squid_ssl_bump.log
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting step2_squid_ssl_bump.sh =====" | tee $LOG_FILE

# squid の cert をエラー cert に差し替える (例: proxy_error.crt/proxy_error.key)
cp -f /usr/local/squid/etc/certs/proxy_error.crt /usr/local/squid/etc/certs/proxy.crt
cp -f /usr/local/squid/etc/certs/proxy_error.key /usr/local/squid/etc/certs/proxy.key

# squid 起動
/usr/local/squid/sbin/squid -s

# 確認
ps aux | grep squid | grep -v grep | tee -a $LOG_FILE
netstat -tulnp | grep 8080 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== step2_squid_ssl_bump.sh completed =====" | tee -a $LOG_FILE
