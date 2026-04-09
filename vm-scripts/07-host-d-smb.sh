#!/bin/bash
# ==============================================================
# 07-host-d-smb.sh — Host D: Internal SMB VM
#                     (replaces SMB/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: Samba 3.5.0 file server (compiled from source)
# Vuln: CVE-2017-7494 — SambaCry RCE via writable share
# Network: net_3 (10.10.3.14)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST D (Internal SMB) VM..."

# Install build dependencies for Samba 3.5.0
apt-get install -y --no-install-recommends \
    build-essential \
    libldap2-dev \
    libpopt-dev \
    libreadline-dev \
    python2 \
    pkg-config \
    libacl1-dev \
    libattr1-dev

# Python2 symlink (required by Samba 3.x build)
ln -sf /usr/bin/python2 /usr/bin/python 2>/dev/null || true

# ── Compile Samba 3.5.0 from source ──
TARBALL="$PROJECT_ROOT/SMB/samba/05e389aff7d3de16561006b35332a881-samba-3.5.0.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: Samba tarball not found at $TARBALL"
    exit 1
fi

cd /tmp
cp "$TARBALL" .
tar xzf *.tar.gz
cd samba-3.5.0/source3

CFLAGS="-Wno-error=deprecated-declarations" \
    ./configure --prefix=/usr/local/samba \
    --disable-cups --without-ads --without-krb5 \
    --without-ldap --without-pam

CFLAGS="-Wno-error=deprecated-declarations -Wno-error" \
    make -j$(nproc) || make -j1
make install

# Register shared libraries
echo "/usr/local/samba/lib" > /etc/ld.so.conf.d/samba.conf
ldconfig

cd /
rm -rf /tmp/samba* /tmp/*.tar.gz

# ── Create share directory ──
mkdir -p /srv/samba/share
chmod 777 /srv/samba/share
mkdir -p /usr/local/samba/var/log/samba
mkdir -p /usr/local/samba/etc

# ── Vulnerable config — writable anonymous share ──
cat > /usr/local/samba/etc/smb.conf <<'EOF'
[global]
workgroup = VULNLAB
server string = Vulnerable Samba
map to guest = Bad User
log file = /usr/local/samba/var/log/samba/%m.log
max log size = 50

[public]
path = /srv/samba/share
browseable = yes
writable = yes
guest ok = yes
create mask = 0777
directory mask = 0777
EOF

# Copy exploit
if [ -f "$PROJECT_ROOT/SMB/samba/42060.py" ]; then
    cp "$PROJECT_ROOT/SMB/samba/42060.py" /exploits/
fi

# ── Create systemd services ──
cat > /etc/systemd/system/samba-smbd-vuln.service <<'EOF'
[Unit]
Description=Vulnerable Samba smbd 3.5.0 (CVE-2017-7494)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/samba/sbin/smbd --foreground --no-process-group -s /usr/local/samba/etc/smb.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/samba-nmbd-vuln.service <<'EOF'
[Unit]
Description=Vulnerable Samba nmbd 3.5.0
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/samba/sbin/nmbd --foreground --no-process-group -s /usr/local/samba/etc/smb.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable samba-smbd-vuln samba-nmbd-vuln
systemctl start samba-smbd-vuln samba-nmbd-vuln

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_3 (Internal)
    enp0s8:
      addresses:
        - 10.10.3.14/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.3.3
        - to: 10.10.1.0/24
          via: 10.10.3.3
        - to: 10.10.2.0/24
          via: 10.10.3.3
        - to: 10.10.4.0/24
          via: 10.10.3.3
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host D (Internal SMB) VM provisioned."
echo "    IP: 10.10.3.14 (net_3)"
echo "    Service: Samba 3.5.0 on ports 139, 445"
echo "    CVE: CVE-2017-7494 (SambaCry)"
