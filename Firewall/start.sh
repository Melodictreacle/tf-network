#!/bin/sh
# =====================================================
# VulnCorp Firewall/Gateway — Entrypoint
# Enables IP forwarding so this container acts as a
# router between DMZ and all internal networks.
# =====================================================

echo "[*] VulnCorp Gateway starting..."

# Enable IP forwarding (requires --privileged or NET_ADMIN cap)
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || \
    sysctl -w net.ipv4.ip_forward=1 2>/dev/null || \
    echo "[!] Warning: Could not enable IP forwarding (need --privileged)"

echo "[*] IP forwarding enabled"
echo "[*] Starting SSH daemon on port 22..."

# Start sshd in foreground
exec /usr/sbin/sshd -D -e
