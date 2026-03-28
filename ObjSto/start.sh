#!/bin/bash
set -e

# Start MariaDB directly (service command may not work in containers)
mysqld_safe --skip-grant-tables &
sleep 3

# Create OwnCloud database and user
mysql -e "CREATE DATABASE IF NOT EXISTS owncloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null || true
mysql -e "CREATE USER IF NOT EXISTS 'owncloud'@'%' IDENTIFIED BY 'owncloud';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'%';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
echo "MariaDB ready — owncloud database created."

# Start Redis
redis-server /etc/redis/redis.conf --daemonize yes
echo "Redis ready."

# Start MinIO if binary exists
if [ -x /usr/local/bin/minio ]; then
    MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}" \
    MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin123}" \
    /usr/local/bin/minio server /data/minio --console-address ":9001" &
    echo "MinIO started."
else
    echo "MinIO binary not found — skipping."
fi

# Keep container alive
tail -f /dev/null
