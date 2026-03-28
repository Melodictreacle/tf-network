#!/bin/bash
set -e

# Auto-configure OwnCloud with MariaDB on Host G
DB_HOST="${OWNCLOUD_DB_HOST:-host-g-storage}"
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

echo "Starting Apache..."
exec apachectl -D FOREGROUND
