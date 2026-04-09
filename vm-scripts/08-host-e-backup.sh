#!/bin/bash
# ==============================================================
# 08-host-e-backup.sh — Host E: Backup Server VM
#                        (replaces Backup/Dockerfile)
#
# Base: Ubuntu 20.04
# Role: rsync 3.1.1 + SSH + NFS backup server
# Vuln: CVE-2014-9512 (rsync path traversal) + NFS no_root_squash
# Networks: net_1 (.15), net_2 (.15), net_3 (.15), net_4 (.15)
# ** BRIDGES ALL 4 INTERNAL NETWORKS **
# ==============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-common.sh"

echo "[*] Provisioning HOST E (Backup Server) VM..."

# Install SSH, NFS and build deps for rsync
apt-get install -y --no-install-recommends \
    build-essential \
    libpopt-dev \
    openssh-server \
    nfs-kernel-server

# ── Compile rsync 3.1.1 from source (CVE-2014-9512) ──
TARBALL="$PROJECT_ROOT/Backup/rsync/rsync-3.1.1.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo "[!] ERROR: rsync tarball not found at $TARBALL"
    exit 1
fi

cd /tmp
cp "$TARBALL" .
tar xzf *.tar.gz
cd rsync-3.1.1
./configure
make -j$(nproc)
make install
cd /
rm -rf /tmp/rsync* /tmp/*.tar.gz

# ── SSH — weak config for lab ──
mkdir -p /run/sshd
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "root:backup123" | chpasswd

systemctl enable ssh
systemctl restart ssh

# ── rsync — open daemon (CVE-2014-9512) ──
mkdir -p /srv/backup
cat > /etc/rsyncd.conf <<'EOF'
[backup]
path = /srv/backup
comment = Backup share
read only = no
auth users =
uid = root
gid = root
EOF

# Create systemd service for rsyncd
cat > /etc/systemd/system/rsyncd-vuln.service <<'EOF'
[Unit]
Description=Vulnerable rsync 3.1.1 daemon (CVE-2014-9512)
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/rsync --daemon
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rsyncd-vuln
systemctl start rsyncd-vuln

# ── NFS — no_root_squash (Config Flaw) ──
mkdir -p /srv/nfs/share
chmod 777 /srv/nfs/share
echo "/srv/nfs/share *(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
exportfs -ra 2>/dev/null || true

systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server 2>/dev/null || true

# ── Network configuration ──
# This VM needs 4 interfaces (one per internal subnet)
cat > /etc/netplan/60-vulnlab.yaml <<'EOF'
network:
  version: 2
  ethernets:
    # net_1 (Perimeter)
    enp0s8:
      addresses:
        - 10.10.1.15/24
      routes:
        - to: 10.10.0.0/24
          via: 10.10.1.3
    # net_2 (Mail & Auth)
    enp0s9:
      addresses:
        - 10.10.2.15/24
    # net_3 (Internal)
    enp0s10:
      addresses:
        - 10.10.3.15/24
    # net_4 (Storage)
    enp0s16:
      addresses:
        - 10.10.4.15/24
EOF

netplan apply 2>/dev/null || echo "[!] Netplan apply failed — configure networking manually"

echo "[✓] Host E (Backup Server) VM provisioned."
echo "    IPs: 10.10.1.15, 10.10.2.15, 10.10.3.15, 10.10.4.15"
echo "    Services: SSH (22), rsync (873), NFS (2049)"
echo "    CVE: CVE-2014-9512, NFS no_root_squash"
echo "    ⚠  BRIDGES ALL 4 INTERNAL NETWORKS"
