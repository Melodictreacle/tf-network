# ==============================================================
# main.tf - Provider, Images, Networks, Volumes
# ==============================================================
#
# 4-Network Architecture:
#
#   net_1 (10.10.1.0/24) — Perimeter / DMZ
#         Attacker, A (MailGW), C (FTP), E (Backup),
#         F (Cloud), H (WebDAV), J (NetInf)
#
#   net_2 (10.10.2.0/24) — Mail & Auth
#         A (MailGW), B (MailSt), E (Backup), I (LDAP)
#
#   net_3 (10.10.3.0/24) — Internal / Compute
#         C (FTP), D (SMB), E (Backup)
#
#   net_4 (10.10.4.0/24) — Storage & Cloud
#         E (Backup), F (Cloud), G (ObjSto), H (WebDAV)
#
# Host E (Backup) bridges ALL 4 networks — compromise it for
# full lateral movement across the entire lab.
# ==============================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# =================================================================
#  Docker Images — Kali from Hub, all others built from source
# =================================================================

resource "docker_image" "kali" {
  name         = "kalilinux/kali-rolling:latest"
  keep_locally = true
}

resource "docker_image" "host_a" {
  name = "vuln-lab-mailgw"
  build {
    context    = "${path.module}/MailGW"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_b" {
  name = "vuln-lab-mailstore"
  build {
    context    = "${path.module}/MailSt"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_c" {
  name = "vuln-lab-ftp"
  build {
    context    = "${path.module}/FTP"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_d" {
  name = "vuln-lab-smb"
  build {
    context    = "${path.module}/SMB"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_e" {
  name = "vuln-lab-backup"
  build {
    context    = "${path.module}/Backup"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_f" {
  name = "vuln-lab-cloud"
  build {
    context    = "${path.module}/Cloud"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_g" {
  name = "vuln-lab-storage"
  build {
    context    = "${path.module}/ObjSto"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_h" {
  name = "vuln-lab-webdav"
  build {
    context    = "${path.module}/WebDAV"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_i" {
  name = "vuln-lab-ldap"
  build {
    context    = "${path.module}/DirAut"
    dockerfile = "Dockerfile"
  }
}

resource "docker_image" "host_j" {
  name = "vuln-lab-netinfra"
  build {
    context    = "${path.module}/NetInf"
    dockerfile = "Dockerfile"
  }
}

# =================================================================
#  4 Separate Networks
# =================================================================

resource "docker_network" "net_1" {
  name   = "${var.project_name}-net-1-perimeter"
  driver = "bridge"

  ipam_config {
    subnet  = "10.10.1.0/24"
    gateway = "10.10.1.1"
  }

  labels {
    label = "zone"
    value = "perimeter"
  }
}

resource "docker_network" "net_2" {
  name   = "${var.project_name}-net-2-mail-auth"
  driver = "bridge"

  ipam_config {
    subnet  = "10.10.2.0/24"
    gateway = "10.10.2.1"
  }

  labels {
    label = "zone"
    value = "mail-auth"
  }
}

resource "docker_network" "net_3" {
  name   = "${var.project_name}-net-3-internal"
  driver = "bridge"

  ipam_config {
    subnet  = "10.10.3.0/24"
    gateway = "10.10.3.1"
  }

  labels {
    label = "zone"
    value = "internal"
  }
}

resource "docker_network" "net_4" {
  name   = "${var.project_name}-net-4-storage"
  driver = "bridge"

  ipam_config {
    subnet  = "10.10.4.0/24"
    gateway = "10.10.4.1"
  }

  labels {
    label = "zone"
    value = "storage"
  }
}

# =================================================================
#  Volumes
# =================================================================

resource "docker_volume" "owncloud_data" {
  name = "${var.project_name}-owncloud-data"
}

resource "docker_volume" "minio_data" {
  name = "${var.project_name}-minio-data"
}

resource "docker_volume" "ldap_data" {
  name = "${var.project_name}-ldap-data"
}

resource "docker_volume" "samba_data" {
  name = "${var.project_name}-samba-data"
}

resource "docker_volume" "backup_data" {
  name = "${var.project_name}-backup-data"
}

resource "docker_volume" "owncloud_db" {
  name = "${var.project_name}-owncloud-db"
}