#!/bin/bash

LOG_FILE=/home/troubleshoot/step1_block_dns.log
echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== Starting step1_block_dns.sh =====" | tee $LOG_FILE

# dnsmasq 設定投入
echo "address=/cybereason.net/0.0.0.0" > /etc/dnsmasq.d/block_cybereason.conf

# dnsmasq 再起動
systemctl restart dnsmasq

# 設定確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | dnsmasq config:" | tee -a $LOG_FILE
cat /etc/dnsmasq.d/block_cybereason.conf | tee -a $LOG_FILE

# digで確認
echo "$(date '+%Y-%m-%d %H:%M:%S') | dig cybereason.net:" | tee -a $LOG_FILE
dig cybereason.net @127.0.0.1 | tee -a $LOG_FILE

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== step1_block_dns.sh completed =====" | tee -a $LOG_FILE

# 最後に tcpdump を自動キャプチャ (300秒)
echo "$(date '+%Y-%m-%d %H:%M:%S') | Capturing DNS traffic with tcpdump for 300 sec..." | tee -a $LOG_FILE
sudo timeout 300 tcpdump -i any port 53 -w /home/troubleshoot/step1_tcpdump_dns.pcap
echo "$(date '+%Y-%m-%d %H:%M:%S') | tcpdump capture saved: /home/troubleshoot/step1_tcpdump_dns.pcap" | tee -a $LOG_FILE
