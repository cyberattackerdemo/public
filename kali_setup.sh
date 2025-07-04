#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive
LOG_FILE="/home/kali/cloud-init-debug.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Start Custom Script Execution ===="
sleep 30

echo "Installing curl and wget to retrieve GPG key"
apt-get -o Acquire::http::No-Cache=True update || true
apt-get -o Acquire::http::No-Cache=True install -y curl wget gnupg || true

wget -qO /usr/share/keyrings/kali-archive-keyring.asc https://archive.kali.org/archive-key.asc

echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.asc] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list

apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get -o Acquire::http::No-Cache=True update || true

echo "Installing metasploit and PostgreSQL"
apt-get -o Acquire::http::No-Cache=True install -y curl metasploit-framework postgresql-16 || true

systemctl enable postgresql || true
systemctl start postgresql || true

echo "Downloading test file"
mkdir -p /home/kali/kali
curl -L https://raw.githubusercontent.com/cyberattackerdemo/main/main/FakeRansom_JP.ps1 -o /home/kali/kali/FakeRansom_JP.ps1 || true
chown kali:kali /home/kali/kali/FakeRansom_JP.ps1

echo "Checking if msfconsole is installed"
if which msfconsole; then
    echo "msfconsole installed"
else
    echo "msfconsole not found"
fi

echo "==== End Custom Script Execution ===="
