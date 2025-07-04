#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive
LOG_FILE="/home/kali/cloud-init-debug.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Start Custom Script Execution ===="
sleep 30

echo "Adding GPG Key"
wget -q -O /usr/share/keyrings/kali-archive-keyring.asc https://archive.kali.org/archive-key.asc

echo "Configuring sources.list"
echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.asc] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list

echo "Cleaning apt lists and updating"
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get update

echo "Installing curl, metasploit, postgresql"
apt-get install -y curl metasploit-framework postgresql

echo "Enabling and starting postgresql"
systemctl enable postgresql
systemctl start postgresql

echo "Downloading test file"
mkdir -p /home/kali/kali
curl -L https://raw.githubusercontent.com/cyberattackerdemo/main/main/FakeRansom_JP.ps1 -o /home/kali/kali/FakeRansom_JP.ps1
chown kali:kali /home/kali/kali/FakeRansom_JP.ps1

echo "Checking msfconsole installation"
which msfconsole || echo "msfconsole not found"

echo "==== End Custom Script Execution ===="
