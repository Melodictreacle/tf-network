#!/bin/bash
# ==============================================================
# 11-host-h-webdav.sh — Host H: WebDAV Share VM
#
# Base: Ubuntu 20.04
# Vuln: CVE-2021-41773 — path traversal RCE
# Networks: net_1 (10.10.1.18), net_4 (10.10.4.18)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST H (WebDAV) VM..."

apt-get install -y --no-install-recommends \
    build-essential libapr1-dev libaprutil1-dev libpcre3-dev

TARBALL="$PROJECT_ROOT/WebDAV/httpd/1edb1895661473ea530209e29b83a982-httpd-2.4.49.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: httpd tarball not found at $TARBALL"; exit 1
fi

cd /tmp && cp "$TARBALL" . && tar xzf *.tar.gz && cd httpd-2.4.49
./configure --prefix=/usr/local/apache2 \
    --enable-so --enable-modules=most \
    --enable-cgi --enable-cgid --enable-mpms-shared=all
make -j$(nproc) && make install
cd / && rm -rf /tmp/httpd* /tmp/*.tar.gz

# Vulnerable config
sed -i 's|#LoadModule cgid_module|LoadModule cgid_module|' /usr/local/apache2/conf/httpd.conf
sed -i 's|#LoadModule cgi_module|LoadModule cgi_module|'   /usr/local/apache2/conf/httpd.conf
sed -i 's|Require all denied|Require all granted|g'        /usr/local/apache2/conf/httpd.conf
sed -i 's|#ServerName www.example.com:80|ServerName localhost|' /usr/local/apache2/conf/httpd.conf

[ -f "$PROJECT_ROOT/WebDAV/httpd/50383.sh" ] && cp "$PROJECT_ROOT/WebDAV/httpd/50383.sh" /exploits/

cat > /etc/systemd/system/httpd-vuln.service <<'EOF'
[Unit]
Description=Vulnerable Apache httpd 2.4.49 (CVE-2021-41773)
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/apache2/bin/httpd -k start
ExecStop=/usr/local/apache2/bin/httpd -k stop
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl disable apache2 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
systemctl daemon-reload && systemctl enable httpd-vuln && systemctl start httpd-vuln

cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      addresses: [10.10.1.18/24]
      routes: [{to: 10.10.0.0/24, via: 10.10.1.3}]
    enp0s9:
      addresses: [10.10.4.18/24]
EOF
netplan apply 2>/dev/null || true

echo "[✓] Host H provisioned. IPs: 10.10.1.18, 10.10.4.18 | CVE-2021-41773"
