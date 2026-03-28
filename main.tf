# ==============================================================
# main.tf - Provider, Images, Networks, Volumes
# ==============================================================
#
# Network Attack Matrix implemented via Docker network zones:
#
#   perimeter     : Attacker, A, C, F, H, J    (DMZ / attacker-facing)
#   mail_zone     : A, B, E                     (mail relay path)
#   internal_zone : C, D, E                     (FTP/SMB segment)
#   storage_zone  : E, F, G, H                  (storage/sync segment)
#   auth_zone     : A, B, C, E, F, I            (LDAP authentication)
#   infra_zone    : A, E, J                      (DNS / network infra)
#
# Host E (Backup) bridges all internal zones via SSH.
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
#  Network Zones (matches Network_Attack_Paths matrix)
# =================================================================

resource "docker_network" "perimeter" {
  name   = "${var.project_name}-perimeter"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/24"
    gateway = "172.20.0.1"
  }

  labels {
    label = "zone"
    value = "perimeter"
  }
}

resource "docker_network" "mail_zone" {
  name   = "${var.project_name}-mail-zone"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.1.0/24"
    gateway = "172.20.1.1"
  }

  labels {
    label = "zone"
    value = "mail"
  }
}

resource "docker_network" "internal_zone" {
  name   = "${var.project_name}-internal-zone"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.2.0/24"
    gateway = "172.20.2.1"
  }

  labels {
    label = "zone"
    value = "internal"
  }
}

resource "docker_network" "storage_zone" {
  name   = "${var.project_name}-storage-zone"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.3.0/24"
    gateway = "172.20.3.1"
  }

  labels {
    label = "zone"
    value = "storage"
  }
}

resource "docker_network" "auth_zone" {
  name   = "${var.project_name}-auth-zone"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.4.0/24"
    gateway = "172.20.4.1"
  }

  labels {
    label = "zone"
    value = "auth"
  }
}

resource "docker_network" "infra_zone" {
  name   = "${var.project_name}-infra-zone"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.5.0/24"
    gateway = "172.20.5.1"
  }

  labels {
    label = "zone"
    value = "infra"
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