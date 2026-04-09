#!/bin/bash
# ==============================================================
# 10-host-g-storage.sh — Host G: Storage Server VM
#                         (replaces ObjSto/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: MinIO object storage + MariaDB + Redis
# Vuln: CVE-2023-28432 — MinIO env var info disclosure
# Network: net_4 (10.10.4.17)
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST G (Storage Server) VM..."

# ── Phase 1: Install Go and compile MinIO ──
apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gcc \
    libc6-dev \
    mariadb-server \
    redis-server

# Install Go 1.20
if [ ! -d /usr/local/go ]; then
    wget -q https://go.dev/dl/go1.20.14.linux-amd64.tar.gz -O /tmp/go.tar.gz
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
fi
export PATH="/usr/local/go/bin:${PATH}"
export GOPATH="/go"

# Compile MinIO from source (CVE-2023-28432)
TARBALL="$PROJECT_ROOT/ObjSto/minio/minio-RELEASE.2023-03-13T19-46-17Z.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: MinIO tarball not found at $TARBALL"
    echo "    MinIO will be skipped."
else
    cd /tmp
    cp "$TARBALL" .
    tar xzf *.tar.gz
    cd minio-*
    go build -o /usr/local/bin/minio .
    chmod +x /usr/local/bin/minio
    cd /
    rm -rf /tmp/minio* /tmp/*.tar.gz
fi

# ── Phase 2: Configure MariaDB ──
# Allow remote connections from Host F (OwnCloud)
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' \
    /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl enable mariadb
systemctl start mariadb

# Create OwnCloud database and user
mysql -e "CREATE DATABASE IF NOT EXISTS owncloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null || true
mysql -e "CREATE USER IF NOT EXISTS 'owncloud'@'%' IDENTIFIED BY 'owncloud';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'%';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
echo "[✓] MariaDB ready — owncloud database created."

# ── Phase 3: Configure Redis ──
# Listen on all interfaces (for OwnCloud on Host F)
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf 2>/dev/null || true
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf 2>/dev/null || true

systemctl enable redis-server
systemctl restart redis-server
echo "[✓] Redis ready."

# ── Phase 4: Configure MinIO service ──
mkdir -p /data/minio

if [ -x /usr/local/bin/minio ]; then
    cat > /etc/systemd/system/minio-vuln.service <<'EOF'
[Unit]
Description=Vulnerable MinIO (CVE-2023-28432)
After=network.target

[Service]
Type=simple
Environment="MINIO_ROOT_USER=minioadmin"
Environment="MINIO_ROOT_PASSWORD=minioadmin123"
ExecStart=/usr/local/bin/minio server /data/minio --console-address ":9001"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable minio-vuln
    systemctl start minio-vuln
    echo "[✓] MinIO started."
fi

# ── Network configuration ──
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_4 (Storage)
    enp0s8:
      addresses:
        - 10.10.4.17/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.4.3
        - to: 10.10.1.0/24
          via: 10.10.4.3
        - to: 10.10.2.0/24
          via: 10.10.4.3
        - to: 10.10.3.0/24
          via: 10.10.4.3
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host G (Storage Server) VM provisioned."
echo "    IP: 10.10.4.17 (net_4)"
echo "    Services: MariaDB (3306), Redis (6379), MinIO (9000/9001)"
echo "    CVE: CVE-2023-28432"
