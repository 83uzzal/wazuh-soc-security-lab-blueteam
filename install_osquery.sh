#!/bin/bash
set -e

echo "[+] Installing Osquery"

sudo apt update
sudo apt install -y osquery

sudo systemctl enable osqueryd
sudo systemctl restart osqueryd

echo "[+] Osquery installed"
