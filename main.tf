# ==============================================================
# main.tf - Provider and Shared Config (VMware Workstation)
# ==============================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    vmworkstation = {
      source  = "elsudano/vmworkstation"
      version = "1.0.3"
    }
  }
}

provider "vmworkstation" {
  user     = var.vmw_user
  password = var.vmw_password
  url      = var.vmw_url
}

# In VMware Workstation, complex networking (like our 5 distinct subnets)
# relies on Virtual Network Editor setup on the host (e.g., VMnet2, VMnet3...)
# For standard Terraform provisioning, VMs are cloned from the base image
# and attached to specific VMnets or bridged networks.
# 
# IMPORTANT PRE-REQUISITE on the Host:
# You must map 5 custom VMnet adapters in Virtual Network Editor:
#   - VMnet10 -> DMZ        (10.10.0.0/24)
#   - VMnet11 -> net_1      (10.10.1.0/24)
#   - VMnet12 -> net_2      (10.10.2.0/24)
#   - VMnet13 -> net_3      (10.10.3.0/24)
#   - VMnet14 -> net_4      (10.10.4.0/24)