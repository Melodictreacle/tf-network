# ==============================================================
# mock-hosts.tf - Mock Test Deployment
# Deploys only: Website, Host G (Storage), and Host F (Cloud)
# ==============================================================

# ======== 1. Website VM ========
# Public facing web server with a PHP backdoor (DMZ)
resource "vmworkstation_vm" "website" {
  sourceid     = var.base_vm_path
  denomination = "${var.project_name}-website"
  description  = "VulnLab Website Testing VM"
  path         = "${var.deploy_path}\\${var.project_name}-website"
  processors   = 1
  memory       = 1024

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = "192.168.1.100" # Placeholder: VMware provider limitation. Use static base or local-exec loop for real provisioning.
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/tf-network"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /opt/vulnlab && sudo mv /tmp/tf-network /opt/vulnlab",
      "sudo chmod +x /opt/vulnlab/vm-scripts/*.sh",
      "sudo bash -c '(sleep 3; /opt/vulnlab/vm-scripts/02-website.sh) > /tmp/provision.log 2>&1 &'"
    ]
  }
}

# ======== 2. Host G (Storage) ========
# Database, Redis, and MinIO object storage (net_4)
resource "vmworkstation_vm" "host_g" {
  sourceid     = var.base_vm_path
  denomination = "${var.project_name}-host-g"
  description  = "VulnLab Host G Storage Testing VM"
  path         = "${var.deploy_path}\\${var.project_name}-host-g"
  processors   = 1
  memory       = 1500

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = "192.168.1.100" # Placeholder: VMware provider limitation. Use static base or local-exec loop for real provisioning.
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/tf-network"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /opt/vulnlab && sudo mv /tmp/tf-network /opt/vulnlab",
      "sudo chmod +x /opt/vulnlab/vm-scripts/*.sh",
      "sudo bash -c '(sleep 3; /opt/vulnlab/vm-scripts/10-host-g-storage.sh) > /tmp/provision.log 2>&1 &'"
    ]
  }
}

# ======== 3. Host F (Cloud) ========
# OwnCloud application interface (net_1, net_4) - Depends on Host G
resource "vmworkstation_vm" "host_f" {
  sourceid     = var.base_vm_path
  denomination = "${var.project_name}-host-f"
  description  = "VulnLab Host F Cloud Testing VM"
  path         = "${var.deploy_path}\\${var.project_name}-host-f"
  processors   = 1
  memory       = 1024

  # Ensures Host G (Database Server) spins up before Host F (App Server)
  depends_on = [vmworkstation_vm.host_g]

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = "192.168.1.100"
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/tf-network"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /opt/vulnlab && sudo mv /tmp/tf-network /opt/vulnlab",
      "sudo chmod +x /opt/vulnlab/vm-scripts/*.sh",
      "sudo bash -c '(sleep 3; /opt/vulnlab/vm-scripts/09-host-f-cloud.sh) > /tmp/provision.log 2>&1 &'"
    ]
  }
}
