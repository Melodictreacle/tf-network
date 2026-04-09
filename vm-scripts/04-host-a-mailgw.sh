#!/bin/bash
# ==============================================================
# 04-host-a-mailgw.sh — Host A: Mail Gateway VM
#                        (replaces MailGW/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: OpenSMTPD mail gateway
# Vuln: CVE-2020-7247 — OpenSMTPD auth bypass → RCE
# Networks: net_1 (10.10.1.11), net_2 (10.10.2.11)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST A (Mail Gateway) VM..."

# Install OpenSMTPD + python3 (for exploit)
apt-get install -y --no-install-recommends \
    opensmtpd \
    python3

# Place the original vulnerable source tarball for reference
if [ -f "$PROJECT_ROOT/MailGW/opensmtpd/f88f1c1fa4c7c321004398da02e885fd-opensmtpd-6.6.1p1.tar.gz" ]; then
    mkdir -p /src
    cp "$PROJECT_ROOT/MailGW/opensmtpd/f88f1c1fa4c7c321004398da02e885fd-opensmtpd-6.6.1p1.tar.gz" /src/
fi

# ── Vulnerable SMTP config (CVE-2020-7247 context) ──
# Permissive relay — accepts mail from anyone, relays to anywhere
cat > /etc/smtpd.conf <<'EOF'
listen on 0.0.0.0 port 25
table aliases file:/etc/aliases
action "local" mbox alias <aliases>
action "relay" relay
match from any for local action "local"
match for any action "relay"
EOF

touch /etc/aliases

# Copy exploit script
if [ -f "$PROJECT_ROOT/MailGW/opensmtpd/47984.py" ]; then
    cp "$PROJECT_ROOT/MailGW/opensmtpd/47984.py" /exploits/
fi

# Stop default smtpd if running, then enable our config
systemctl stop smtpd 2>/dev/null || true
systemctl enable smtpd
systemctl start smtpd

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_1 (Perimeter)
    enp0s8:
      addresses:
        - 10.10.1.11/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.1.3
    # net_2 (Mail & Auth)
    enp0s9:
      addresses:
        - 10.10.2.11/24
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host A (Mail Gateway) VM provisioned."
echo "    IPs: 10.10.1.11 (net_1), 10.10.2.11 (net_2)"
echo "    Service: OpenSMTPD on port 25"
echo "    CVE: CVE-2020-7247"
