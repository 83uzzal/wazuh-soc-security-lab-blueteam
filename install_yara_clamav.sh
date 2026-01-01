#!/bin/bash
set -e

echo "[+] Installing YARA and ClamAV"

sudo apt update
sudo apt install -y yara clamav clamav-daemon

sudo systemctl stop clamav-freshclam || true
sudo freshclam
sudo systemctl start clamav-freshclam

echo "[+] YARA and ClamAV installed"
