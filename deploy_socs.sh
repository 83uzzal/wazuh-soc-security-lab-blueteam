#!/bin/bash
# =========================================================
# deploy_socs.sh
# FINAL & SAFE SOC Lab Deployment Script
# Author: Alamgir SOC Lab
# =========================================================

set -euo pipefail

REPO_DIR="$(pwd)"
echo "[+] SOC Lab deployment started from: $REPO_DIR"

# ------------------ PRE-CHECK ------------------
if [ ! -d /var/ossec ]; then
  echo "[!] Wazuh not installed. Exiting."
  exit 1
fi

# =========================================================
# ===================== WAZUH =============================
# =========================================================
echo "[+] Deploying Wazuh configuration..."

sudo mkdir -p /var/ossec/etc/rules
sudo mkdir -p /var/ossec/etc/decoders

# Backup existing files
timestamp=$(date +%F-%H%M%S)
sudo cp -a /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak.$timestamp 2>/dev/null || true
sudo cp -a /var/ossec/etc/local_internal_options.conf /var/ossec/etc/local_internal_options.conf.bak.$timestamp 2>/dev/null || true

# Copy configs
[ -f "$REPO_DIR/wazuh/ossec.conf" ] && \
sudo cp "$REPO_DIR/wazuh/ossec.conf" /var/ossec/etc/ossec.conf

[ -f "$REPO_DIR/wazuh/local_internal_options.conf" ] && \
sudo cp "$REPO_DIR/wazuh/local_internal_options.conf" /var/ossec/etc/local_internal_options.conf

[ -f "$REPO_DIR/wazuh/rules/local_rules.xml" ] && \
sudo cp "$REPO_DIR/wazuh/rules/local_rules.xml" /var/ossec/etc/rules/local_rules.xml

# Decoders
if compgen -G "$REPO_DIR/wazuh/decoders/*.xml" > /dev/null; then
  sudo cp "$REPO_DIR/wazuh/decoders/"*.xml /var/ossec/etc/decoders/
fi

# Permissions (CRITICAL)
sudo chown -R root:wazuh /var/ossec/etc
sudo chmod 640 /var/ossec/etc/*.conf
sudo chmod 640 /var/ossec/etc/rules/*.xml
sudo chmod 640 /var/ossec/etc/decoders/*.xml

# Validate Wazuh config
echo "[+] Validating Wazuh configuration..."
sudo /var/ossec/bin/wazuh-analysisd -t

# =========================================================
# ==================== SURICATA ===========================
# =========================================================
echo "[+] Deploying Suricata configuration..."

sudo mkdir -p /etc/suricata/rules

[ -f "$REPO_DIR/suricata/suricata.yaml" ] && \
sudo cp "$REPO_DIR/suricata/suricata.yaml" /etc/suricata/suricata.yaml

if [ -d "$REPO_DIR/suricata/rules" ]; then
  sudo cp "$REPO_DIR/suricata/rules/"* /etc/suricata/rules/
fi

sudo chown -R root:root /etc/suricata
sudo chmod 640 /etc/suricata/suricata.yaml

# =========================================================
# ===================== COWRIE ============================
# =========================================================
echo "[+] Deploying Cowrie configuration..."

sudo mkdir -p /opt/cowrie-auto-installer/config

[ -f "$REPO_DIR/cowrie/cowrie.cfg" ] && \
sudo cp "$REPO_DIR/cowrie/cowrie.cfg" /opt/cowrie-auto-installer/config/cowrie.cfg

[ -f "$REPO_DIR/cowrie/userdb.txt" ] && \
sudo cp "$REPO_DIR/cowrie/userdb.txt" /opt/cowrie-auto-installer/config/userdb.txt

# Cowrie runs as cowrie user
sudo chown -R cowrie:cowrie /opt/cowrie-auto-installer

# =========================================================
# ===================== OSQUERY ===========================
# =========================================================
echo "[+] Deploying Osquery configuration..."

sudo mkdir -p /etc/osquery/packs

[ -f "$REPO_DIR/osquery/osquery.conf" ] && \
sudo cp "$REPO_DIR/osquery/osquery.conf" /etc/osquery/osquery.conf

if [ -d "$REPO_DIR/osquery/packs" ]; then
  sudo cp "$REPO_DIR/osquery/packs/"*.conf /etc/osquery/packs/
fi

sudo chown -R root:root /etc/osquery

# =========================================================
# ======================= YARA ===========================
# =========================================================
echo "[+] Deploying YARA files..."

sudo mkdir -p /opt/yara/rules

if [ -d "$REPO_DIR/yara/rules" ]; then
  sudo cp "$REPO_DIR/yara/rules/"*.yar /opt/yara/rules/
fi

if [ -f "$REPO_DIR/yara/yara.sh" ]; then
  sudo cp "$REPO_DIR/yara/yara.sh" /var/ossec/active-response/bin/yara.sh
  sudo chown root:wazuh /var/ossec/active-response/bin/yara.sh
  sudo chmod 750 /var/ossec/active-response/bin/yara.sh
fi

# =========================================================
# ====================== CALDERA =========================
# =========================================================
echo "[+] Deploying Caldera configuration..."

sudo mkdir -p /opt/caldera/conf

[ -f "$REPO_DIR/caldera/config.yml" ] && \
sudo cp "$REPO_DIR/caldera/config.yml" /opt/caldera/config.yml

[ -f "$REPO_DIR/caldera/plugins.yml" ] && \
sudo cp "$REPO_DIR/caldera/plugins.yml" /opt/caldera/plugins.yml

[ -f "$REPO_DIR/caldera/caldera.rules" ] && \
sudo cp "$REPO_DIR/caldera/caldera.rules" /opt/caldera/caldera.rules

[ -f "$REPO_DIR/caldera/conf/server.yml" ] && \
sudo cp "$REPO_DIR/caldera/conf/server.yml" /opt/caldera/conf/server.yml

sudo chown -R $USER:$USER /opt/caldera

# =========================================================
# ================== SERVICE RESTART =====================
# =========================================================
echo "[+] Restarting services..."

sudo systemctl restart wazuh-manager
sudo systemctl restart suricata || true
sudo systemctl restart osqueryd || true

echo "================================================="
echo "[✓] SOC Lab deployment completed successfully!"
echo "================================================="
