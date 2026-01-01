#!/bin/bash
set -e

echo "[+] Installing MITRE Caldera"

sudo apt update
sudo apt install -y git python3 python3-pip

sudo git clone https://github.com/mitre/caldera.git /opt/caldera || true
cd /opt/caldera

sudo pip3 install -r requirements.txt

echo "[+] Caldera installed"
echo "[!] Start with: cd /opt/caldera && python3 server.py --insecure"
