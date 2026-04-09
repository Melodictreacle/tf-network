#!/bin/bash

set -e

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

echo "[+] Updating packages..."
apt-get update

echo "[+] Installing dependencies..."
apt-get install -y --no-install-recommends \
    opensmtpd \
    python3

echo "[+] Cleaning up..."
rm -rf /var/lib/apt/lists/*

echo "[+] Creating directories..."
mkdir -p /src
mkdir -p /exploits

echo "[+] Copy required files (ensure they exist in same dir before running)..."
cp opensmtpd/f88f1c1fa4c7c321004398da02e885fd-opensmtpd-6.6.1p1.tar.gz /src/
cp opensmtpd/47984.py /exploits/

echo "[+] Writing vulnerable smtpd config..."
cat <<EOF > /etc/smtpd.conf
listen on 0.0.0.0 port 25
table aliases file:/etc/aliases
action "local" mbox alias <aliases>
action "relay" relay
match from any for local action "local"
match for any action "relay"
EOF

echo "[+] Creating aliases file..."
touch /etc/aliases

echo "[+] Setup complete."

echo "[+] Starting OpenSMTPD..."
smtpd -d -f /etc/smtpd.conf
