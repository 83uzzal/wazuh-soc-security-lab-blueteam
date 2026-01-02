#!/bin/bash
# ============================================================
# SOC Home Lab - One Command Installer (FINAL)
#
# Components:
#   - Wazuh 4.14 (Manager + Dashboard)
#   - Suricata IDS
#   - YARA
#   - ClamAV
#   - Osquery
#   - Cowrie Honeypot
#   - Deploy SOC configs via deploy_socs.sh
#
# OS: Ubuntu 22.04 / 24.04
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Run as root: sudo ./install_all.sh"
    exit 1
fi

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------
SERVER_IP=$(hostname -I | awk '{print $1}')
LOG_FILE="/var/log/soc_install.log"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
exec > >(tee -a "$LOG_FILE") 2>&1

log()  { echo -e "\n[INFO] $(date '+%F %T') - $1"; }
fail() { echo -e "\n[ERROR] $1"; exit 1; }
trap 'fail "Installation failed at line $LINENO"' ERR

log "SOC Home Lab installer started"

# ------------------------------------------------------------
# Base packages
# ------------------------------------------------------------
log "Updating system & installing base packages"

apt update -y
apt install -y \
    curl gnupg apt-transport-https software-properties-common \
    ca-certificates jq git python3 python3-venv python3-pip \
    libssl-dev libffi-dev build-essential authbind dos2unix

# ------------------------------------------------------------
# Wazuh 4.14
# ------------------------------------------------------------
install_wazuh() {
    if systemctl list-units --type=service | grep -q wazuh-manager; then
        log "Wazuh already installed, skipping"
        return
    fi

    log "Installing Wazuh 4.14"
    curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
    bash wazuh-install.sh -a | tee /tmp/wazuh-install.log

    DASH_USER=$(grep -m1 "User:" /tmp/wazuh-install.log | awk '{print $2}')
    DASH_PASS=$(grep -m1 "Password:" /tmp/wazuh-install.log | awk '{print $2}')

    echo "$DASH_USER:$DASH_PASS" > /root/wazuh_dashboard_creds.txt
    chmod 600 /root/wazuh_dashboard_creds.txt

    log "Wazuh installed successfully"
}

# ------------------------------------------------------------
# Suricata IDS
# ------------------------------------------------------------
install_suricata() {
    if command -v suricata &>/dev/null; then
        log "Suricata already installed, skipping"
        return
    fi

    log "Installing Suricata IDS"
    apt install -y suricata suricata-update libpcap0.8

    PRIMARY_IF=$(ip route | awk '/default/ {print $5; exit}')
    sed -i "s|interface: .*|interface: $PRIMARY_IF|" /etc/suricata/suricata.yaml

    suricata-update
    systemctl enable suricata
    systemctl restart suricata

    log "Suricata running on interface: $PRIMARY_IF"
}

# ------------------------------------------------------------
# YARA + ClamAV
# ------------------------------------------------------------
install_yara_clamav() {
    log "Installing YARA & ClamAV"

    apt install -y yara clamav clamav-daemon

    systemctl stop clamav-freshclam || true
    freshclam

    systemctl enable clamav-daemon
    systemctl restart clamav-daemon
}

# ------------------------------------------------------------
# Osquery
# ------------------------------------------------------------
install_osquery() {
    if command -v osqueryd &>/dev/null; then
        log "Osquery already installed, skipping"
        return
    fi

    log "Installing Osquery"
    curl -L https://pkg.osquery.io/deb/osquery_5.20.0-1.linux_amd64.deb -o /tmp/osquery.deb
    dpkg -i /tmp/osquery.deb || apt -f install -y

    mkdir -p /etc/osquery

    cat <<EOF >/etc/osquery/osquery.conf
{
  "options": {
    "logger_plugin": "filesystem",
    "logger_path": "/var/log/osquery",
    "utc": "true"
  },
  "schedule": {
    "system_info": {
      "query": "SELECT hostname, cpu_brand, physical_memory FROM system_info;",
      "interval": 3600
    }
  }
}
EOF

    systemctl enable osqueryd
    systemctl restart osqueryd
}

# ------------------------------------------------------------
# Cowrie Honeypot
# ------------------------------------------------------------
install_cowrie() {
    log "Installing Cowrie honeypot"

    if systemctl list-unit-files | grep -q cowrie.service; then
        log "Cowrie already installed, skipping"
        return
    fi

    [[ -f ./install_cowrie.sh ]] || fail "install_cowrie.sh not found"

    dos2unix ./install_cowrie.sh
    chmod +x ./install_cowrie.sh

    ./install_cowrie.sh
}

# ------------------------------------------------------------
# Deploy SOC Configurations
# ------------------------------------------------------------
deploy_soc_configs() {
    log "Deploying SOC configuration files"

    [[ -f ./deploy_socs.sh ]] || fail "deploy_socs.sh not found"

    dos2unix ./deploy_socs.sh || true
    chmod +x ./deploy_socs.sh

    ./deploy_socs.sh
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------
log "Starting full SOC Home Lab installation"

install_wazuh
install_suricata
install_yara_clamav
install_osquery
install_cowrie
deploy_soc_configs

# ------------------------------------------------------------
# Final Output
# ------------------------------------------------------------
log "INSTALLATION COMPLETED SUCCESSFULLY"

echo "==========================================="
echo "        SOC HOME LAB READY"
echo "==========================================="
echo " URL      : https://$SERVER_IP:443"
echo " Username : $DASH_USER"
echo " Password : $DASH_PASS"
echo " Logs : $LOG_FILE"
echo "==========================================="
