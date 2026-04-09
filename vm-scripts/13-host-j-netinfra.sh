#!/bin/bash
# ==============================================================
# 13-host-j-netinfra.sh — Host J: Network Infrastructure VM
#
# Base: Ubuntu 20.04
# Role: Squid 5.0.1 proxy + BIND9 DNS
# Vuln: CVE-2020-11945 (Squid cache poisoning)
#       + BIND9 unrestricted zone transfers
# Network: net_1 (10.10.1.20)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST J (Network Infra) VM..."

apt-get install -y --no-install-recommends \
    build-essential libssl-dev pkg-config autoconf automake libtool \
    libltdl-dev \
    bind9 bind9utils

# Compile Squid 5.0.1 from source (CVE-2020-11945)
TARBALL="$PROJECT_ROOT/NetInf/squid/squid-SQUID_5_0_1.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: Squid tarball not found at $TARBALL"; exit 1
fi

cd /tmp && cp "$TARBALL" . && tar xzf *.tar.gz && cd squid-*
([ -f bootstrap.sh ] && sh bootstrap.sh || true)
([ -f configure ] || autoreconf -fi 2>&1 || true)
./configure --prefix=/usr/local/squid --with-openssl --disable-arch-native
make -j$(nproc) && make install
cd / && rm -rf /tmp/squid* /tmp/*.tar.gz

# Create Squid runtime dirs and user
useradd -r -s /usr/sbin/nologin squid 2>/dev/null || true
mkdir -p /usr/local/squid/var/{cache,logs,run}
chown -R squid:squid /usr/local/squid/var 2>/dev/null || true

# BIND9 — allow unrestricted zone transfers
cat > /etc/bind/named.conf.options <<'EOF'
options {
  directory "/var/cache/bind";
  recursion yes;
  allow-query { any; };
  allow-transfer { any; };
  allow-recursion { any; };
  forwarders { 8.8.8.8; 8.8.4.4; };
  dnssec-validation no;
  listen-on { any; };
};
EOF

# Squid — permissive proxy
cat > /usr/local/squid/etc/squid.conf <<'EOF'
http_port 3128
acl all src 0.0.0.0/0
http_access allow all
EOF

# Systemd services
cat > /etc/systemd/system/squid-vuln.service <<'EOF'
[Unit]
Description=Vulnerable Squid 5.0.1 (CVE-2020-11945)
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/squid/sbin/squid -N
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable named squid-vuln
systemctl restart named
systemctl start squid-vuln

cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      addresses: [10.10.1.20/24]
      routes:
        - {to: 10.10.0.0/24, via: 10.10.1.3}
        - {to: 10.10.2.0/24, via: 10.10.1.3}
        - {to: 10.10.3.0/24, via: 10.10.1.3}
        - {to: 10.10.4.0/24, via: 10.10.1.3}
EOF
netplan apply 2>/dev/null || true

echo "[✓] Host J provisioned. IP: 10.10.1.20 | DNS:53, Squid:3128"
