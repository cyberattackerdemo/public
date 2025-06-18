#!/bin/bash

echo "address=/example.com/0.0.0.0" | sudo tee /etc/dnsmasq.d/block-example.conf

echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq

echo "Logging to /var/log/dnsmasq.log"
