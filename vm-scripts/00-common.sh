#!/bin/bash
# ==============================================================
# 00-common.sh — Common setup for all VulnLab VMs
# Source this at the top of every provisioning script:
#   source /vagrant/vm-scripts/00-common.sh
# ==============================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Directory where source tarballs are stored (adjust to your layout)
# When using Vagrant, this is typically the synced folder.
# When provisioning manually, copy the project tree to the VM first.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  VulnLab VM Provisioner"
echo "  Host: $(hostname)"
echo "  Date: $(date)"
echo "=========================================="

apt-get update -qq

# Create exploit staging directory
mkdir -p /exploits
