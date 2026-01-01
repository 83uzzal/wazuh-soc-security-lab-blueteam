#!/bin/bash
set -e

echo "[+] Starting full SOC lab installation"
chmod +x install_*.sh

./install_wazuh_suricata.sh
./install_cowrie.sh
./install_osquery.sh
./install_yara_clamav.sh
./install_caldera.sh

echo "[+] Full installation completed. Update rules:"
echo "sudo suricata-update && sudo systemctl restart suricata"
