#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
LOG_FILE="/home/kali/cloud-init-debug.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Start Custom Script Execution ===="
sleep 30

echo "Updating sources.list to stable mirror"
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list

echo "Fetching and adding Kali GPG key"
wget -q -O /usr/share/keyrings/kali-archive-keyring.asc https://archive.kali.org/archive-key.asc

echo "Updating package lists with retry and --fix-missing"
RETRY_COUNT=0
until apt-get -o Acquire::http::No-Cache=True update --fix-missing; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ "$RETRY_COUNT" -ge 5 ]; then
        echo "apt-get update failed after 5 attempts"
        exit 1
    fi
    echo "Retrying apt-get update... attempt $RETRY_COUNT"
    sleep 10
done

echo "Cleaning up apt cache"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Updating package lists again with retry"
RETRY_COUNT=0
until apt-get -o Acquire::http::No-Cache=True update --fix-missing; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ "$RETRY_COUNT" -ge 5 ]; then
        echo "apt-get update failed after 5 attempts"
        exit 1
    fi
    echo "Retrying apt-get update... attempt $RETRY_COUNT"
    sleep 10
done

echo "Installing metasploit and PostgreSQL with --fix-missing"
apt-get -o Acquire::http::No-Cache=True install -y curl metasploit-framework postgresql --fix-missing

echo "Enabling and starting PostgreSQL"
systemctl enable postgresql || true
systemctl start postgresql || true

echo "Downloading test file"
mkdir -p /home/kali/kali
curl -L https://raw.githubusercontent.com/cyberattackerdemo/main/main/FakeRansom_JP.ps1 -o /home/kali/kali/FakeRansom_JP.ps1
chown kali:kali /home/kali/kali/FakeRansom_JP.ps1

echo "Checking if msfconsole is installed"
which msfconsole || echo "msfconsole not found"

echo "==== End Custom Script Execution ===="
