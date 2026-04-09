#!/bin/bash
# ==============================================================
# 09-host-f-cloud.sh — Host F: Cloud Sync VM
#                       (replaces Cloud/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: OwnCloud 10.x file sync
# Vuln: CVE-2023-49103 — graphapi phpinfo() info disclosure
# Networks: net_1 (10.10.1.16), net_4 (10.10.4.16)
# Depends: Host G (MariaDB + Redis on net_4)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST F (Cloud Sync) VM..."

# Install Apache + PHP stack for OwnCloud
apt-get install -y --no-install-recommends \
    apache2 \
    libapache2-mod-php \
    php-mysql \
    php-gd \
    php-curl \
    php-zip \
    php-xml \
    php-mbstring \
    php-intl \
    php-json \
    php-bz2 \
    php-redis \
    bzip2 \
    curl \
    sudo

# ── Extract OwnCloud application ──
TARBALL="$PROJECT_ROOT/Cloud/Owncloud/owncloud-complete-20230313.tar.bz2"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: OwnCloud tarball not found at $TARBALL"
    exit 1
fi

cd /tmp
cp "$TARBALL" .
tar xjf owncloud-complete-20230313.tar.bz2
mv owncloud /var/www/
chown -R www-data:www-data /var/www/owncloud
rm -rf /tmp/*

# ── Apache config for OwnCloud ──
cat > /etc/apache2/sites-available/owncloud.conf <<'EOF'
<VirtualHost *:80>
  DocumentRoot /var/www/owncloud
  <Directory /var/www/owncloud>
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF

a2ensite owncloud
a2dissite 000-default
a2enmod rewrite headers env dir mime

# Create data directory
mkdir -p /var/www/owncloud/data
chown -R www-data:www-data /var/www/owncloud/data

# ── Create startup script (waits for Host G's MariaDB) ──
cat > /usr/local/bin/owncloud-init.sh <<'SCRIPT'
#!/bin/bash
set -e

DB_HOST="${OWNCLOUD_DB_HOST:-10.10.4.17}"
DB_NAME="${OWNCLOUD_DB_NAME:-owncloud}"
DB_USER="${OWNCLOUD_DB_USER:-owncloud}"
DB_PASS="${OWNCLOUD_DB_PASS:-owncloud}"
ADMIN_USER="${OWNCLOUD_ADMIN_USER:-admin}"
ADMIN_PASS="${OWNCLOUD_ADMIN_PASS:-admin}"

# Wait for MariaDB on Host G to be ready
echo "Waiting for MariaDB on ${DB_HOST}..."
for i in $(seq 1 60); do
    if php -r "new PDO('mysql:host=${DB_HOST};port=3306', '${DB_USER}', '${DB_PASS}');" 2>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    echo "  Attempt $i/60 — waiting..."
    sleep 3
done

# Run OwnCloud installer if not already configured
if [ ! -f /var/www/owncloud/config/config.php ]; then
    echo "Running OwnCloud auto-install..."
    cd /var/www/owncloud
    sudo -u www-data php occ maintenance:install \
        --database "mysql" \
        --database-host "${DB_HOST}" \
        --database-name "${DB_NAME}" \
        --database-user "${DB_USER}" \
        --database-pass "${DB_PASS}" \
        --admin-user "${ADMIN_USER}" \
        --admin-pass "${ADMIN_PASS}" \
        --data-dir "/var/www/owncloud/data" 2>&1 || true

    # Add trusted domains
    sudo -u www-data php occ config:system:set trusted_domains 0 --value="*" 2>/dev/null || true
fi

echo "OwnCloud initialization complete."
SCRIPT
chmod +x /usr/local/bin/owncloud-init.sh

# ── Create systemd service for OwnCloud init ──
cat > /etc/systemd/system/owncloud-init.service <<'EOF'
[Unit]
Description=OwnCloud DB initialization (one-shot)
After=network-online.target apache2.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/owncloud-init.sh
RemainAfterExit=yes
Environment="OWNCLOUD_DB_HOST=10.10.4.17"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Apache
systemctl enable apache2
systemctl restart apache2

systemctl daemon-reload
systemctl enable owncloud-init

# Run init now (will fail if Host G not up yet — that's OK, systemd retries on boot)
systemctl start owncloud-init 2>/dev/null || \
    echo "[!] OwnCloud init deferred — Host G (MariaDB) not ready yet"

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_1 (Perimeter)
    enp0s8:
      addresses:
        - 10.10.1.16/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.1.3
    # net_4 (Storage) — Host G is here
    enp0s9:
      addresses:
        - 10.10.4.16/24
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host F (Cloud Sync) VM provisioned."
echo "    IPs: 10.10.1.16 (net_1), 10.10.4.16 (net_4)"
echo "    Service: OwnCloud on port 80"
echo "    CVE: CVE-2023-49103"
echo "    Depends: Host G (10.10.4.17) for MariaDB + Redis"
