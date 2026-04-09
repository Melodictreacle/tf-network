#!/bin/bash
# ==============================================================
# 02-website.sh — VulnCorp Website VM (replaces Website/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: Company website with hidden PHP backdoor
# Vuln: /.maintenance.php command injection
# Network: DMZ (10.10.0.2)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning WEBSITE VM..."

# Install Apache + PHP 7.4
apt-get install -y --no-install-recommends \
    apache2 \
    libapache2-mod-php \
    php \
    php-cli

# Enable mod_rewrite
a2enmod rewrite

# ── Deploy website files ──
cp "$PROJECT_ROOT/Website/index.php" /var/www/html/index.php
cp "$PROJECT_ROOT/Website/cmd.php"   /var/www/html/.maintenance.php

# Set permissions
chown -R www-data:www-data /var/www/html
chmod 644 /var/www/html/index.php
chmod 644 /var/www/html/.maintenance.php

# Remove default index.html
rm -f /var/www/html/index.html

# Allow .htaccess overrides
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
    /etc/apache2/apache2.conf

# Restart Apache
systemctl enable apache2
systemctl restart apache2

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      addresses:
        - 10.10.0.2/24
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Website VM provisioned."
echo "    IP: 10.10.0.2 (DMZ)"
echo "    Service: Apache + PHP on port 80"
echo "    Backdoor: /.maintenance.php?token=VulnCorp2024&cmd=<command>"
