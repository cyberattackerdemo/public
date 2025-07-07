#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
LOG_FILE="/home/kali/cloud-init-debug.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==== Start Custom Script Execution ===="

echo "Temporarily disabling signature checks to fetch essential packages"
apt-get -o Acquire::AllowInsecureRepositories=true \
        -o Acquire::AllowDowngradeToInsecureRepositories=true \
        -o Acquire::Check-Valid-Until=false \
        -o Acquire::AllowWeakRepositories=true \
        --allow-unauthenticated \
        update

echo "Installing wget and curl"
apt-get install -y wget curl

echo "Fetching and adding Kali GPG key directly"
wget https://archive.kali.org/archive-key.asc -O /etc/apt/trusted.gpg.d/kali-archive-key.asc

echo "Restoring normal apt behavior and updating package lists"
apt-get update

echo "Installing metasploit and PostgreSQL"
apt-get install -y metasploit-framework postgresql

echo "Enabling and starting PostgreSQL"
systemctl enable postgresql || true
systemctl start postgresql || true

echo "Downloading test file"
curl -L https://raw.githubusercontent.com/cyberattackerdemo/main/main/FakeRansom_JP.ps1 -o /home/kali/FakeRansom_JP.ps1
chown kali:kali /home/kali/FakeRansom_JP.ps1

echo "Checking msfconsole"
which msfconsole || echo "msfconsole not found"

echo "==== End Custom Script Execution ===="
