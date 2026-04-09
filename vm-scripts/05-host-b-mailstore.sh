#!/bin/bash
# ==============================================================
# 05-host-b-mailstore.sh — Host B: Mail Store VM
#                           (replaces MailSt/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: Postfix + Dovecot mail store
# Vuln: CVE-2011-1720 (Postfix mem corruption) + Config Flaw
# Network: net_2 (10.10.2.12)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST B (Mail Store) VM..."

# Pre-seed Postfix debconf selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string vuln-lab.local" | debconf-set-selections

# Install Postfix and Dovecot
apt-get install -y --no-install-recommends \
    postfix \
    dovecot-imapd \
    dovecot-pop3d

# Copy VDA patch for reference
if [ -f "$PROJECT_ROOT/MailSt/postfix/postfix-2.5.6-vda-ng.patch.gz" ]; then
    cp "$PROJECT_ROOT/MailSt/postfix/postfix-2.5.6-vda-ng.patch.gz" /exploits/
fi

# ── Postfix — open relay config (CVE-2011-1720 context) ──
postconf -e "inet_interfaces = all"
postconf -e "mynetworks = 0.0.0.0/0"
postconf -e "smtpd_recipient_restrictions = permit"

# ── Dovecot — plaintext auth, no SSL (Config Flaw) ──
sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/' \
    /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
sed -i 's/ssl = required/ssl = no/' \
    /etc/dovecot/conf.d/10-ssl.conf 2>/dev/null || true

# Enable and start services
systemctl enable postfix dovecot
systemctl restart postfix
systemctl restart dovecot

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_2 (Mail & Auth)
    enp0s8:
      addresses:
        - 10.10.2.12/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.2.3
        - to: 10.10.1.0/24
          via: 10.10.2.3
        - to: 10.10.3.0/24
          via: 10.10.2.3
        - to: 10.10.4.0/24
          via: 10.10.2.3
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host B (Mail Store) VM provisioned."
echo "    IP: 10.10.2.12 (net_2)"
echo "    Services: Postfix (25), Dovecot IMAP (143), POP3 (110)"
echo "    CVE: CVE-2011-1720, Config Flaw (plaintext auth)"
