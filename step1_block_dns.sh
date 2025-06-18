#!/bin/bash

echo "address=/cybereason.net/0.0.0.0" | sudo tee /etc/dnsmasq.d/block-cybereason.conf

echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq

echo "Logging to /var/log/dnsmasq.log"
