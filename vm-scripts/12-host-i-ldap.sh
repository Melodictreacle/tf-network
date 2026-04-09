#!/bin/bash
# ==============================================================
# 12-host-i-ldap.sh — Host I: Directory Auth VM
#
# Base: Ubuntu 20.04
# Role: OpenLDAP 2.4.18 (compiled from source)
# Vuln: Anonymous / null DN bind auth bypass
# Network: net_2 (10.10.2.19)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST I (Directory Auth) VM..."

apt-get install -y --no-install-recommends \
    build-essential libssl-dev groff-base

TARBALL="$PROJECT_ROOT/DirAut/openldap/openldap-2.4.18.tgz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: OpenLDAP tarball not found at $TARBALL"; exit 1
fi

cd /tmp && cp "$TARBALL" . && tar xzf *.tgz && cd openldap-2.4.18
./configure --prefix=/usr/local/openldap \
    --enable-slapd --enable-ldap \
    --disable-bdb --disable-hdb
make depend && make -j$(nproc) && make install
cd / && rm -rf /tmp/openldap* /tmp/*.tgz

# Create required directories
mkdir -p /usr/local/openldap/var/run /usr/local/openldap/var/openldap-data

# Vulnerable config — allows anonymous/null DN bind
cat > /usr/local/openldap/etc/openldap/slapd.conf <<'EOF'
include /usr/local/openldap/etc/openldap/schema/core.schema
include /usr/local/openldap/etc/openldap/schema/cosine.schema
include /usr/local/openldap/etc/openldap/schema/inetorgperson.schema
pidfile /usr/local/openldap/var/run/slapd.pid
argsfile /usr/local/openldap/var/run/slapd.args
database ldif
suffix "dc=vuln-lab,dc=local"
rootdn "cn=admin,dc=vuln-lab,dc=local"
rootpw admin123
directory /usr/local/openldap/var/openldap-data
access to * by * read
EOF

# Seed LDAP directory
if [ -f "$PROJECT_ROOT/DirAut/seed.ldif" ]; then
    /usr/local/openldap/sbin/slapadd \
        -f /usr/local/openldap/etc/openldap/slapd.conf \
        -l "$PROJECT_ROOT/DirAut/seed.ldif"
fi

# Create systemd service
cat > /etc/systemd/system/slapd-vuln.service <<'EOF'
[Unit]
Description=Vulnerable OpenLDAP 2.4.18 (null DN bypass)
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/openldap/libexec/slapd -d 256 -h ldap://0.0.0.0:389/
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl enable slapd-vuln && systemctl start slapd-vuln

cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      addresses: [10.10.2.19/24]
      routes:
        - {to: 10.10.0.0/24, via: 10.10.2.3}
        - {to: 10.10.1.0/24, via: 10.10.2.3}
        - {to: 10.10.3.0/24, via: 10.10.2.3}
        - {to: 10.10.4.0/24, via: 10.10.2.3}
EOF
netplan apply 2>/dev/null || true

echo "[✓] Host I provisioned. IP: 10.10.2.19 | LDAP port 389 | Null DN bypass"
