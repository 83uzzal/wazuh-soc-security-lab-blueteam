#!/bin/bash
set -e

echo "[+] Installing Cowrie Honeypot"

sudo apt update
sudo apt install -y git python3-venv libssl-dev libffi-dev build-essential

sudo useradd -r -s /bin/false cowrie || true
sudo mkdir -p /opt/cowrie
sudo chown cowrie:cowrie /opt/cowrie

sudo -u cowrie git clone https://github.com/cowrie/cowrie.git /opt/cowrie

sudo -u cowrie python3 -m venv /opt/cowrie/venv
sudo -u cowrie /opt/cowrie/venv/bin/pip install --upgrade pip
sudo -u cowrie /opt/cowrie/venv/bin/pip install -r /opt/cowrie/requirements.txt

# Deploy config
sudo cp cowrie/cowrie.cfg /opt/cowrie/etc/cowrie.cfg

echo "[+] Cowrie installed"
echo "[!] Run manually: sudo -u cowrie /opt/cowrie/bin/cowrie start"
