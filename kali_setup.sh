#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive
LOG_FILE="/home/kali/cloud-init-debug.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Start Custom Script Execution ===="

sleep 30

apt-get update || true
apt-get install -y curl gnupg || true

curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list

apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update --fix-missing || true

apt-get install -y curl metasploit-framework postgresql || true

systemctl enable postgresql || true
systemctl start postgresql || true

mkdir -p /home/kali/kali
curl -L https://raw.githubusercontent.com/cyberattackerdemo/main/main/FakeRansom_JP.ps1 -o /home/kali/kali/FakeRansom_JP.ps1 || true
chown kali:kali /home/kali/kali/FakeRansom_JP.ps1

if which msfconsole; then
    echo "msfconsole installed" >> "$LOG_FILE"
else
    echo "msfconsole not found" >> "$LOG_FILE"
fi

echo "==== End Custom Script Execution ===="
