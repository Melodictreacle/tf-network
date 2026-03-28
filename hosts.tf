# ==============================================================
# hosts.tf - All containers (Attacker + Hosts A-J)
# ==============================================================
#
# Host Vulnerability Details:
# +----------+--------------+------------------------+-----------------+
# | Host     | Services     | Vulnerability          | CVE / Flaw      |
# +----------+--------------+------------------------+-----------------+
# | A MailGW | opensmtpd    | rce_auth_bypass        | CVE-2020-7247   |
# | B MailSt | postfix      | mem_corruption_dos     | CVE-2011-1720   |
# |          | dovecot      | unauth_access          | Config Flaw     |
# | C FTP    | vsftpd       | malicious_backdoor_rce | CVE-2011-2523   |
# | D SMB    | samba         | rce_sambacry           | CVE-2017-7494   |
# | E Backup | rsync        | path_traversal_write   | CVE-2014-9512   |
# |          | nfs          | unauth_root_squash     | Config Flaw     |
# | F Cloud  | owncloud     | info_disclosure_api    | CVE-2023-49103  |
# | G ObjSto | minio        | information_disclosure | CVE-2023-28432  |
# | H WebDAV | httpd        | path_traversal_rce     | CVE-2021-41773  |
# | I DirAut | openldap     | auth_bypass_null_dn    | Config Flaw     |
# | J NetInf | bind9        | dns_zone_transfer      | Config Flaw     |
# |          | squid        | cache_poisoning        | CVE-2020-11945  |
# +----------+--------------+------------------------+-----------------+

# =================================================================
#  ATTACKER - Kali Linux (from Docker Hub)
# =================================================================

resource "docker_container" "attacker" {
  name     = "${var.project_name}-attacker"
  hostname = "attacker"
  image    = docker_image.kali.image_id

  command = ["sleep", "infinity"]

  networks_advanced { name = docker_network.perimeter.name }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "attacker"
  }
}

# =================================================================
#  HOST A - Mail Gateway (OpenSMTPD 6.6.1p1)
#  CVE-2020-7247 : OpenSMTPD auth bypass -> RCE
#  Networks: perimeter, mail_zone, auth_zone, infra_zone
# =================================================================

resource "docker_container" "host_a" {
  name     = "${var.project_name}-host-a"
  hostname = "host-a-mailgw"
  image    = docker_image.host_a.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.mail_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }
  networks_advanced { name = docker_network.infra_zone.name }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "mail-gateway"
  }
  labels {
    label = "cves"
    value = "CVE-2020-7247"
  }
}

# =================================================================
#  HOST B - Mail Store (Postfix + Dovecot)
#  CVE-2011-1720 : Postfix SMTP mem corruption DoS
#  Config Flaw   : Dovecot unauthenticated access
#  Networks: mail_zone, auth_zone
# =================================================================

resource "docker_container" "host_b" {
  name     = "${var.project_name}-host-b"
  hostname = "host-b-mailstore"
  image    = docker_image.host_b.image_id

  networks_advanced { name = docker_network.mail_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "mail-store"
  }
  labels {
    label = "cves"
    value = "CVE-2011-1720,Config-Flaw"
  }
}

# =================================================================
#  HOST C - Legacy FTP (vsftpd 2.3.4)
#  CVE-2011-2523 : vsftpd 2.3.4 backdoor -> RCE
#  Networks: perimeter, internal_zone, auth_zone
# =================================================================

resource "docker_container" "host_c" {
  name     = "${var.project_name}-host-c"
  hostname = "host-c-ftp"
  image    = docker_image.host_c.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.internal_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }

  ports {
    internal = 21
    external = var.exposed_ports["ftp"]
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "legacy-ftp"
  }
  labels {
    label = "cves"
    value = "CVE-2011-2523"
  }
}

# =================================================================
#  HOST D - Internal SMB (Samba 3.5.0)
#  CVE-2017-7494 : SambaCry -> RCE via writable share
#  Networks: internal_zone
# =================================================================

resource "docker_container" "host_d" {
  name     = "${var.project_name}-host-d"
  hostname = "host-d-smb"
  image    = docker_image.host_d.image_id

  networks_advanced { name = docker_network.internal_zone.name }

  volumes {
    volume_name    = docker_volume.samba_data.name
    container_path = "/srv/samba/share"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "internal-smb"
  }
  labels {
    label = "cves"
    value = "CVE-2017-7494"
  }
}

# =================================================================
#  HOST E - Backup Server (rsync 3.1.1 + SSH + NFS)
#  CVE-2014-9512 : rsync path traversal write
#  Config Flaw   : NFS no_root_squash
#  Networks: mail_zone, internal_zone, storage_zone, auth_zone, infra_zone
# =================================================================

resource "docker_container" "host_e" {
  name       = "${var.project_name}-host-e"
  hostname   = "host-e-backup"
  image      = docker_image.host_e.image_id
  privileged = true

  networks_advanced { name = docker_network.mail_zone.name }
  networks_advanced { name = docker_network.internal_zone.name }
  networks_advanced { name = docker_network.storage_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }
  networks_advanced { name = docker_network.infra_zone.name }

  volumes {
    volume_name    = docker_volume.backup_data.name
    container_path = "/srv/backup"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "backup-server"
  }
  labels {
    label = "cves"
    value = "CVE-2014-9512,Config-Flaw-NFS"
  }
}

# =================================================================
#  HOST F - Cloud Sync (OwnCloud)
#  CVE-2023-49103 : graphapi info disclosure (phpinfo leak)
#  Networks: perimeter, storage_zone, auth_zone
#  DB + Cache provided by Host G (storage_zone)
# =================================================================

resource "docker_container" "host_f" {
  name     = "${var.project_name}-host-f"
  hostname = "host-f-cloud"
  image    = docker_image.host_f.image_id

  depends_on = [docker_container.host_g]

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.storage_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }

  ports {
    internal = 80
    external = var.exposed_ports["owncloud"]
  }

  env = [
    "OWNCLOUD_DB_HOST=host-g-storage",
    "OWNCLOUD_DB_NAME=owncloud",
    "OWNCLOUD_DB_USER=owncloud",
    "OWNCLOUD_DB_PASS=owncloud",
    "OWNCLOUD_ADMIN_USER=admin",
    "OWNCLOUD_ADMIN_PASS=admin",
  ]

  volumes {
    volume_name    = docker_volume.owncloud_data.name
    container_path = "/var/www/owncloud/data"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "cloud-sync"
  }
  labels {
    label = "cves"
    value = "CVE-2023-49103"
  }
}

# =================================================================
#  HOST G - Storage Server (MinIO + MariaDB + Redis)
#  CVE-2023-28432 : MinIO environment variable info disclosure
#  Provides: MariaDB (OwnCloud DB), Redis (OwnCloud cache), MinIO
#  Networks: storage_zone
# =================================================================

resource "docker_container" "host_g" {
  name     = "${var.project_name}-host-g"
  hostname = "host-g-storage"
  image    = docker_image.host_g.image_id

  networks_advanced { name = docker_network.storage_zone.name }

  ports {
    internal = 9000
    external = var.exposed_ports["minio_api"]
  }
  ports {
    internal = 9001
    external = var.exposed_ports["minio_ui"]
  }

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data/minio"
  }
  volumes {
    volume_name    = docker_volume.owncloud_db.name
    container_path = "/var/lib/mysql"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "storage-server"
  }
  labels {
    label = "cves"
    value = "CVE-2023-28432"
  }
}

# =================================================================
#  HOST H - WebDAV Share (Apache httpd 2.4.49)
#  CVE-2021-41773 : path traversal -> RCE
#  Networks: perimeter, storage_zone
# =================================================================

resource "docker_container" "host_h" {
  name     = "${var.project_name}-host-h"
  hostname = "host-h-webdav"
  image    = docker_image.host_h.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.storage_zone.name }

  ports {
    internal = 80
    external = var.exposed_ports["httpd"]
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "webdav-share"
  }
  labels {
    label = "cves"
    value = "CVE-2021-41773"
  }
}

# =================================================================
#  HOST I - Directory Auth (OpenLDAP 2.4.18)
#  Config Flaw : anonymous / null DN bind allows auth bypass
#  Networks: auth_zone
# =================================================================

resource "docker_container" "host_i" {
  name     = "${var.project_name}-host-i"
  hostname = "host-i-ldap"
  image    = docker_image.host_i.image_id

  networks_advanced { name = docker_network.auth_zone.name }

  ports {
    internal = 389
    external = var.exposed_ports["ldap"]
  }

  volumes {
    volume_name    = docker_volume.ldap_data.name
    container_path = "/usr/local/openldap/var/openldap-data"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "directory-auth"
  }
  labels {
    label = "cves"
    value = "Config-Flaw-NullDN"
  }
}

# =================================================================
#  HOST J - Network Infra (Squid 5.0.1 + BIND9)
#  Config Flaw    : BIND9 unrestricted zone transfers
#  CVE-2020-11945 : Squid digest auth cache poisoning
#  Networks: perimeter, infra_zone
# =================================================================

resource "docker_container" "host_j" {
  name     = "${var.project_name}-host-j"
  hostname = "host-j-infra"
  image    = docker_image.host_j.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.infra_zone.name }

  ports {
    internal = 53
    external = var.exposed_ports["dns"]
    protocol = "udp"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "network-infra"
  }
  labels {
    label = "cves"
    value = "CVE-2020-11945,Config-Flaw-ZoneXfer"
  }
}
