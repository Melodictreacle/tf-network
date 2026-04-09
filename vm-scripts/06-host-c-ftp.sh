#!/bin/bash
# ==============================================================
# 06-host-c-ftp.sh — Host C: Legacy FTP VM
#                     (replaces FTP/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: vsftpd 2.3.4 (compiled from source)
# Vuln: CVE-2011-2523 — vsftpd smiley backdoor → RCE on port 6200
# Networks: net_1 (10.10.1.13), net_3 (10.10.3.13)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST C (Legacy FTP) VM..."

# Install build dependencies for vsftpd
apt-get install -y --no-install-recommends \
    build-essential \
    libpam0g-dev \
    libcap-dev \
    libssl-dev

# ── Compile vsftpd 2.3.4 from source ──
TARBALL="$PROJECT_ROOT/FTP/vsftpd/2ea5d19978710527bb7444d93b67767a-vsftpd-2.3.4.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: vsftpd tarball not found at $TARBALL"
    echo "    Copy the project tree to the VM first."
    exit 1
fi

cd /tmp
cp "$TARBALL" .
tar xzf *.tar.gz
cd vsftpd-2.3.4

# Add required libraries to Makefile
echo "LIBS = -lcrypt -lpam -lcap -lssl" >> Makefile
make -j$(nproc)
cp vsftpd /usr/local/sbin/
cd /
rm -rf /tmp/vsftpd* /tmp/*.tar.gz

# ── Create FTP user and directories ──
useradd -r -d /var/ftp -s /usr/sbin/nologin ftp 2>/dev/null || true
mkdir -p /var/ftp/pub /var/run/vsftpd/empty /etc/vsftpd
chmod 755 /var/ftp
chmod 777 /var/ftp/pub

# ── Vulnerable config — anonymous access enabled ──
cat > /etc/vsftpd.conf <<'EOF'
listen=YES
listen_port=21
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_root=/var/ftp
secure_chroot_dir=/var/run/vsftpd/empty
EOF

# Copy exploit
if [ -f "$PROJECT_ROOT/FTP/vsftpd/17491.rb" ]; then
    cp "$PROJECT_ROOT/FTP/vsftpd/17491.rb" /exploits/
fi

# ── Create systemd service for vsftpd ──
cat > /etc/systemd/system/vsftpd-vuln.service <<'EOF'
[Unit]
Description=Vulnerable vsftpd 2.3.4 (CVE-2011-2523)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/vsftpd /etc/vsftpd.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vsftpd-vuln
systemctl start vsftpd-vuln

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_1 (Perimeter)
    enp0s8:
      addresses:
        - 10.10.1.13/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.1.3
    # net_3 (Internal)
    enp0s9:
      addresses:
        - 10.10.3.13/24
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host C (Legacy FTP) VM provisioned."
echo "    IPs: 10.10.1.13 (net_1), 10.10.3.13 (net_3)"
echo "    Service: vsftpd 2.3.4 on port 21, backdoor on port 6200"
echo "    CVE: CVE-2011-2523"
