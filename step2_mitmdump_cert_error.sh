#!/bin/bash

# tinyproxy を停止
echo "Stopping tinyproxy..."
sudo systemctl stop tinyproxy

# mitmdump を停止（もし起動中なら）
echo "Stopping mitmdump (if running)..."
sudo pkill -f mitmdump

# 既存ログ削除
echo "Clearing previous mitmproxy.log..."
rm -f /home/troubleshoot/mitmproxy.log

# mitmdump をバックグラウンド起動（ポート8080、SSL証明書検証無効）
echo "Starting mitmdump on port 8080..."
nohup mitmdump --mode regular --listen-port 8080 --set ssl_insecure=true > /home/troubleshoot/mitmproxy.log 2>&1 &

# 確認
sleep 2
if pgrep -f mitmdump > /dev/null; then
    echo "mitmdump is running."
else
    echo "mitmdump failed to start."
fi
