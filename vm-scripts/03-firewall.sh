#!/bin/bash
# ==============================================================
# 03-firewall.sh — VulnCorp Firewall/Gateway VM
#                  (replaces Firewall/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: Gateway bridging DMZ to all 4 internal networks
# Vuln: Weak SSH credentials (root:toor)
# Networks: DMZ (.3), net_1 (.3), net_2 (.3), net_3 (.3), net_4 (.3)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning FIREWALL VM..."

# Install networking tools + OpenSSH
apt-get install -y --no-install-recommends \
    openssh-server \
    iptables \
    iproute2 \
    iputils-ping \
    bash \
    curl \
    net-tools \
    tcpdump

# ── Vulnerable SSH configuration ──
# Set weak root password (intentionally vulnerable)
echo "root:toor" | chpasswd

# Allow root login with password (insecure config)
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config || \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config || \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

systemctl enable ssh
systemctl restart ssh

# ── Enable IP forwarding (router mode) ──
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-vulnlab-forward.conf
sysctl -w net.ipv4.ip_forward=1

# ── Network configuration ──
# This VM needs 5 network interfaces (one per subnet)
# Adjust adapter names to match your hypervisor
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # DMZ interface
    enp0s8:
      addresses:
        - 10.10.0.3/24
    # net_1 (Perimeter)
    enp0s9:
      addresses:
        - 10.10.1.3/24
    # net_2 (Mail & Auth)
    enp0s10:
      addresses:
        - 10.10.2.3/24
    # net_3 (Internal)
    enp0s16:
      addresses:
        - 10.10.3.3/24
    # net_4 (Storage)
    enp0s17:
      addresses:
        - 10.10.4.3/24
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Firewall VM provisioned."
echo "    IPs: 10.10.0.3 (DMZ), 10.10.1-4.3 (internal)"
echo "    SSH: root:toor on port 22"
echo "    IP forwarding: enabled"
