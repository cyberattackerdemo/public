bashCopyEdit#!/bin/bash

set -e

echo "=== プロキシサーバー環境のセットアップを開始 ==="

echo "[1] パッケージのインストール: dnsmasq, tinyproxy, mitmproxy"
sudo apt update
sudo apt install -y dnsmasq tinyproxy mitmproxy logrotate

echo "[2] dnsmasq のログ出力を設定"
sudo tee /etc/dnsmasq.d/logging.conf > /dev/null <<EOF
log-queries
log-facility=/var/log/dnsmasq.log
EOF

sudo touch /var/log/dnsmasq.log
sudo chown dnsmasq /var/log/dnsmasq.log
sudo chmod 644 /var/log/dnsmasq.log

echo "[3] dnsmasq を有効化せず停止状態に設定"
sudo systemctl disable dnsmasq
sudo systemctl stop dnsmasq

echo "[4] logrotate の設定を追加（dnsmasq用）"
sudo tee /etc/logrotate.d/dnsmasq > /dev/null <<EOF
/var/log/dnsmasq.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 644 dnsmasq dnsmasq
    postrotate
        systemctl restart dnsmasq > /dev/null || true
    endscript
}
EOF

echo "[5] tinyproxy を有効化して起動"
sudo systemctl enable tinyproxy
sudo systemctl restart tinyproxy

echo "[6] mitmproxyログ用ディレクトリを作成"
mkdir -p ~/mitmproxy_logs

sudo sed -i 's|^#*LogFile .*|LogFile "/var/log/tinyproxy/tinyproxy.log"|' /etc/tinyproxy/tinyproxy.conf
sudo sed -i 's|^#*LogLevel .*|LogLevel Info|' /etc/tinyproxy/tinyproxy.conf
sudo mkdir -p /var/log/tinyproxy && sudo chown tinyproxy:tinyproxy /var/log/tinyproxy

echo "=== セットアップ完了 ==="
echo "・dnsmasq: 手動起動時に /var/log/dnsmasq.log にログ出力"
echo "・tinyproxy: 現在有効（HTTPプロキシとして使用可）"
echo "・mitmproxy: 使用時はログ出力先 ~/mitmproxy_logs を利用してください"