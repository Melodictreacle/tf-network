#!/bin/bash
# ==============================================================
# 01-attacker.sh — Attacker VM (replaces Attacker/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: Kali-style pentesting workstation
# Network: DMZ ONLY (10.10.0.10)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning ATTACKER VM..."

# Install penetration testing tools
apt-get install -y --no-install-recommends \
    netcat-traditional \
    iputils-ping \
    smbclient \
    rsync \
    dnsutils \
    nmap \
    python3 \
    python3-pip \
    ldap-utils \
    bash \
    curl \
    wget \
    ssh \
    proxychains4 \
    tcpdump \
    net-tools \
    ruby

apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Network configuration ──
# Static IP: 10.10.0.10/24 on the DMZ interface
# Adjust IFACE to match your VM's network adapter name
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # DMZ interface — adjust the adapter name (e.g., enp0s8, eth1)
    enp0s8:
      addresses:
        - 10.10.0.10/24
      routes:
        - to: 10.10.1.0/24
          via: 10.10.0.3
        - to: 10.10.2.0/24
          via: 10.10.0.3
        - to: 10.10.3.0/24
          via: 10.10.0.3
        - to: 10.10.4.0/24
          via: 10.10.0.3
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Attacker VM provisioned."
echo "    IP: 10.10.0.10 (DMZ)"
echo "    Tools: nmap, smbclient, ldap-utils, python3, ruby, proxychains"
