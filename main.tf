# ==============================================================
# main.tf — Provider, Images, Networks, Volumes
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

# ═══════════════════════════════════════════════════════════════
#  Docker Images
# ═══════════════════════════════════════════════════════════════

resource "docker_image" "kali" {
  name         = "kalilinux/kali-rolling:latest"
  keep_locally = true
}

resource "docker_image" "ubuntu" {
  name         = "ubuntu:20.04"
  keep_locally = true
}

resource "docker_image" "owncloud" {
  name         = "owncloud/server:${var.owncloud_version}"
  keep_locally = true
}

resource "docker_image" "minio" {
  name         = "minio/minio:${var.minio_version}"
  keep_locally = true
}

resource "docker_image" "httpd" {
  name         = "httpd:${var.httpd_version}"
  keep_locally = true
}

resource "docker_image" "openldap" {
  name         = "osixia/openldap:${var.openldap_version}"
  keep_locally = true
}

# ═══════════════════════════════════════════════════════════════
#  Network Zones (matches Network_Attack_Paths matrix)
# ═══════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════
#  Volumes
# ═══════════════════════════════════════════════════════════════

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