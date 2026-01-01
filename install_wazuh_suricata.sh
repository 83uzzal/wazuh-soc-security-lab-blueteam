#!/bin/bash
set -e

echo "[+] Installing Wazuh and Suricata"

sudo apt update
sudo apt install -y curl gnupg lsb-release apt-transport-https

# ---------------- WAZUH ----------------
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash wazuh-install.sh -a

# ---------------- SURICATA ----------------
sudo apt install -y suricata suricata-update jq

# Deploy config from Git repo
sudo cp suricata/suricata.yaml /etc/suricata/suricata.yaml

# Safe placeholder rules file
sudo mkdir -p /etc/suricata/rules
sudo tee /etc/suricata/rules/suricata.rules >/dev/null <<EOF
# Rules managed via suricata-update
EOF

sudo systemctl enable suricata
sudo systemctl restart suricata

echo "[+] Wazuh and Suricata installed"
