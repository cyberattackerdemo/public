bashCopyEdit#!/bin/bash

echo "Stopping mitmproxy..."
pkill mitmproxy
sleep 1

echo "Restarting tinyproxy..."
sudo systemctl start tinyproxy

echo "Proxy restored to normal tinyproxy mode"