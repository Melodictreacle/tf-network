# ==============================================================
# hosts.tf — All containers (Attacker + Hosts A–J)
# ==============================================================
#
# Host Vulnerability Details:
# ┌──────────┬──────────────┬────────────────────────┬─────────────────┐
# │ Host     │ Services     │ Vulnerability          │ CVE / Flaw      │
# ├──────────┼──────────────┼────────────────────────┼─────────────────┤
# │ A MailGW │ opensmtpd    │ rce_auth_bypass        │ CVE-2020-7247   │
# │          │ exim         │ rce_command_inject     │ CVE-2019-10149  │
# │ B MailSt │ postfix      │ mem_corruption_dos     │ CVE-2011-1720   │
# │          │ dovecot      │ unauth_access          │ Config Flaw     │
# │ C FTP    │ vsftpd       │ malicious_backdoor_rce │ CVE-2011-2523   │
# │          │ proftpd      │ rce_mod_copy           │ CVE-2015-3306   │
# │ D SMB    │ samba        │ rce_sambacry           │ CVE-2017-7494   │
# │ E Backup │ rsync        │ path_traversal_write   │ CVE-2014-9512   │
# │          │ nfs          │ unauth_root_squash     │ Config Flaw     │
# │ F Cloud  │ owncloud     │ info_disclosure_api    │ CVE-2023-49103  │
# │ G ObjSto │ minio        │ information_disclosure │ CVE-2023-28432  │
# │ H WebDAV │ httpd        │ path_traversal_rce     │ CVE-2021-41773  │
# │ I DirAut │ openldap     │ auth_bypass_null_dn    │ Config Flaw     │
# │ J NetInf │ bind9        │ dns_zone_transfer      │ Config Flaw     │
# │          │ squid        │ cache_poisoning        │ CVE-2020-11945  │
# └──────────┴──────────────┴────────────────────────┴─────────────────┘

# ════════════════════════════════════════════════════════════════
#  ATTACKER — Kali Linux
# ════════════════════════════════════════════════════════════════

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

# ════════════════════════════════════════════════════════════════
#  HOST A — Mail Gateway  (OpenSMTPD + Exim)
#  CVE-2020-7247  : OpenSMTPD auth bypass → RCE
#  CVE-2019-10149 : Exim command injection → RCE
#  Networks: perimeter, mail_zone, auth_zone, infra_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_a" {
  name     = "${var.project_name}-host-a"
  hostname = "host-a-mailgw"
  image    = docker_image.ubuntu.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.mail_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }
  networks_advanced { name = docker_network.infra_zone.name }

  upload {
    content    = <<-SCRIPT
      #!/bin/bash
      set -e; export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq opensmtpd exim4-daemon-light >/dev/null 2>&1
      # OpenSMTPD — permissive config (CVE-2020-7247)
      cat > /etc/smtpd.conf <<'EOF'
      listen on 0.0.0.0 port 25
      table aliases file:/etc/aliases
      action "local" mbox alias <aliases>
      action "relay" relay
      match from any for local action "local"
      match for any action "relay"
      EOF
      # Exim4 on port 587 (CVE-2019-10149)
      sed -i 's/dc_local_interfaces=.*/dc_local_interfaces="0.0.0.0.587"/' /etc/exim4/update-exim4.conf.conf 2>/dev/null || true
      smtpd || true
      service exim4 start 2>/dev/null || true
      exec tail -f /dev/null
    SCRIPT
    file       = "/start.sh"
    executable = true
  }

  command = ["/bin/bash", "/start.sh"]

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
    value = "CVE-2020-7247,CVE-2019-10149"
  }
}

# ════════════════════════════════════════════════════════════════
#  HOST B — Mail Store  (Postfix + Dovecot)
#  CVE-2011-1720  : Postfix SMTP mem corruption DoS
#  Config Flaw    : Dovecot unauthenticated access
#  Networks: mail_zone, auth_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_b" {
  name     = "${var.project_name}-host-b"
  hostname = "host-b-mailstore"
  image    = docker_image.ubuntu.image_id

  networks_advanced { name = docker_network.mail_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }

  upload {
    content    = <<-SCRIPT
      #!/bin/bash
      set -e; export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
      echo "postfix postfix/mailname string ${var.lab_domain}" | debconf-set-selections
      apt-get install -y -qq postfix dovecot-imapd dovecot-pop3d >/dev/null 2>&1
      # Postfix — open relay (CVE-2011-1720 context)
      postconf -e "inet_interfaces = all"
      postconf -e "mynetworks = 0.0.0.0/0"
      # Dovecot — allow plaintext auth, no SSL (Config Flaw)
      sed -i 's/#disable_plaintext_auth = yes/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf 2>/dev/null || true
      sed -i 's/ssl = required/ssl = no/' /etc/dovecot/conf.d/10-ssl.conf 2>/dev/null || true
      postfix start 2>/dev/null || true
      dovecot 2>/dev/null || true
      exec tail -f /dev/null
    SCRIPT
    file       = "/start.sh"
    executable = true
  }

  command = ["/bin/bash", "/start.sh"]

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

# ════════════════════════════════════════════════════════════════
#  HOST C — Legacy FTP  (vsftpd + ProFTPD)
#  CVE-2011-2523  : vsftpd 2.3.4 backdoor → RCE
#  CVE-2015-3306  : ProFTPD mod_copy → file write RCE
#  Networks: perimeter, internal_zone, auth_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_c" {
  name     = "${var.project_name}-host-c"
  hostname = "host-c-ftp"
  image    = docker_image.ubuntu.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.internal_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }

  ports {
    internal = 21
    external = var.exposed_ports["ftp"]
  }

  upload {
    content    = <<-SCRIPT
      #!/bin/bash
      set -e; export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq vsftpd proftpd-basic >/dev/null 2>&1
      # vsftpd — anonymous access enabled (CVE-2011-2523 context)
      cat > /etc/vsftpd.conf <<'EOF'
      listen=YES
      listen_port=21
      anonymous_enable=YES
      local_enable=YES
      write_enable=YES
      anon_upload_enable=YES
      anon_mkdir_write_enable=YES
      anon_root=/srv/ftp
      EOF
      mkdir -p /srv/ftp/pub && chmod 777 /srv/ftp/pub
      # ProFTPD on port 2121 with mod_copy (CVE-2015-3306)
      sed -i 's/Port\s*21/Port 2121/' /etc/proftpd/proftpd.conf 2>/dev/null || true
      vsftpd /etc/vsftpd.conf &
      proftpd --nodaemon &
      exec tail -f /dev/null
    SCRIPT
    file       = "/start.sh"
    executable = true
  }

  command = ["/bin/bash", "/start.sh"]

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
    value = "CVE-2011-2523,CVE-2015-3306"
  }
}

# ════════════════════════════════════════════════════════════════
#  HOST D — Internal SMB  (Samba)
#  CVE-2017-7494  : SambaCry → RCE via writable share
#  Networks: internal_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_d" {
  name     = "${var.project_name}-host-d"
  hostname = "host-d-smb"
  image    = docker_image.ubuntu.image_id

  networks_advanced { name = docker_network.internal_zone.name }

  volumes {
    volume_name    = docker_volume.samba_data.name
    container_path = "/srv/samba/share"
  }

  upload {
    content    = <<-SCRIPT
      #!/bin/bash
      set -e; export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq samba >/dev/null 2>&1
      # Samba — writable anonymous share (CVE-2017-7494 SambaCry)
      cat > /etc/samba/smb.conf <<'EOF'
      [global]
        workgroup = VULNLAB
        server string = Vulnerable Samba
        map to guest = Bad User
        log file = /var/log/samba/%m.log
        max log size = 50
      [public]
        path = /srv/samba/share
        browseable = yes
        writable = yes
        guest ok = yes
        create mask = 0777
        directory mask = 0777
      EOF
      chmod -R 777 /srv/samba/share
      smbd --foreground --no-process-group &
      nmbd --foreground --no-process-group &
      exec tail -f /dev/null
    SCRIPT
    file       = "/start.sh"
    executable = true
  }

  command = ["/bin/bash", "/start.sh"]

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

# ════════════════════════════════════════════════════════════════
#  HOST E — Backup Server  (rsync + NFS + SSH)
#  CVE-2014-9512  : rsync path traversal write
#  Config Flaw    : NFS no_root_squash
#  Networks: mail_zone, internal_zone, storage_zone, auth_zone, infra_zone
#  (bridges all zones — SSH access to everything)
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_e" {
  name       = "${var.project_name}-host-e"
  hostname   = "host-e-backup"
  image      = docker_image.ubuntu.image_id
  privileged = true # needed for NFS

  networks_advanced { name = docker_network.mail_zone.name }
  networks_advanced { name = docker_network.internal_zone.name }
  networks_advanced { name = docker_network.storage_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }
  networks_advanced { name = docker_network.infra_zone.name }

  volumes {
    volume_name    = docker_volume.backup_data.name
    container_path = "/srv/backup"
  }

  upload {
    content    = <<-SCRIPT
      #!/bin/bash
      set -e; export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq rsync openssh-server nfs-kernel-server >/dev/null 2>&1
      # SSH — weak config for lab (password auth)
      mkdir -p /run/sshd
      echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
      echo 'root:backup123' | chpasswd
      # rsync — open daemon (CVE-2014-9512)
      cat > /etc/rsyncd.conf <<'EOF'
      [backup]
        path = /srv/backup
        comment = Backup share
        read only = no
        auth users =
        uid = root
        gid = root
      EOF
      # NFS — no_root_squash (Config Flaw)
      mkdir -p /srv/nfs/share && chmod 777 /srv/nfs/share
      echo "/srv/nfs/share *(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
      /usr/sbin/sshd
      rsync --daemon
      exportfs -ra 2>/dev/null || true
      rpc.nfsd 2>/dev/null || true
      exec tail -f /dev/null
    SCRIPT
    file       = "/start.sh"
    executable = true
  }

  command = ["/bin/bash", "/start.sh"]

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

# ════════════════════════════════════════════════════════════════
#  HOST F — Cloud Sync  (OwnCloud)
#  CVE-2023-49103 : graphapi info disclosure (phpinfo leak)
#  Networks: perimeter, storage_zone, auth_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_f" {
  name     = "${var.project_name}-host-f"
  hostname = "host-f-cloud"
  image    = docker_image.owncloud.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.storage_zone.name }
  networks_advanced { name = docker_network.auth_zone.name }

  ports {
    internal = 8080
    external = var.exposed_ports["owncloud"]
  }

  env = [
    "OWNCLOUD_DOMAIN=localhost:${var.exposed_ports["owncloud"]}",
    "OWNCLOUD_TRUSTED_DOMAINS=localhost",
    "ADMIN_USERNAME=admin",
    "ADMIN_PASSWORD=admin",
  ]

  volumes {
    volume_name    = docker_volume.owncloud_data.name
    container_path = "/mnt/data"
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

# ════════════════════════════════════════════════════════════════
#  HOST G — Object Storage  (MinIO)
#  CVE-2023-28432 : environment variable info disclosure
#  Networks: storage_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_g" {
  name     = "${var.project_name}-host-g"
  hostname = "host-g-objstore"
  image    = docker_image.minio.image_id

  networks_advanced { name = docker_network.storage_zone.name }

  ports {
    internal = 9000
    external = var.exposed_ports["minio_api"]
  }
  ports {
    internal = 9001
    external = var.exposed_ports["minio_ui"]
  }

  env = [
    "MINIO_ROOT_USER=${var.minio_root_user}",
    "MINIO_ROOT_PASSWORD=${var.minio_root_password}",
  ]

  command = ["server", "/data", "--console-address", ":9001"]

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  labels {
    label = "role"
    value = "object-storage"
  }
  labels {
    label = "cves"
    value = "CVE-2023-28432"
  }
}

# ════════════════════════════════════════════════════════════════
#  HOST H — WebDAV Share  (Apache httpd 2.4.49)
#  CVE-2021-41773 : path traversal → RCE
#  Networks: perimeter, storage_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_h" {
  name     = "${var.project_name}-host-h"
  hostname = "host-h-webdav"
  image    = docker_image.httpd.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.storage_zone.name }

  ports {
    internal = 80
    external = var.exposed_ports["httpd"]
  }

  # Custom httpd.conf enabling CGI + permissive directory access (CVE-2021-41773)
  upload {
    content = <<-CONF
      ServerRoot "/usr/local/apache2"
      Listen 80
      LoadModule mpm_event_module modules/mod_mpm_event.so
      LoadModule authz_core_module modules/mod_authz_core.so
      LoadModule alias_module modules/mod_alias.so
      LoadModule dir_module modules/mod_dir.so
      LoadModule cgid_module modules/mod_cgid.so
      LoadModule unixd_module modules/mod_unixd.so
      LoadModule log_config_module modules/mod_log_config.so

      User daemon
      Group daemon
      ServerName host-h-webdav
      DocumentRoot "/usr/local/apache2/htdocs"

      <Directory />
          AllowOverride None
          Require all granted
      </Directory>

      <Directory "/usr/local/apache2/htdocs">
          Options Indexes FollowSymLinks
          AllowOverride None
          Require all granted
      </Directory>

      ScriptAlias /cgi-bin/ "/usr/local/apache2/cgi-bin/"
      <Directory "/usr/local/apache2/cgi-bin">
          AllowOverride None
          Options +ExecCGI
          Require all granted
      </Directory>

      ErrorLog /proc/self/fd/2
      CustomLog /proc/self/fd/1 common
    CONF
    file    = "/usr/local/apache2/conf/httpd.conf"
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

# ════════════════════════════════════════════════════════════════
#  HOST I — Directory Auth  (OpenLDAP)
#  Config Flaw : anonymous / null DN bind allows auth bypass
#  Networks: auth_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_i" {
  name     = "${var.project_name}-host-i"
  hostname = "host-i-ldap"
  image    = docker_image.openldap.image_id

  networks_advanced { name = docker_network.auth_zone.name }

  ports {
    internal = 389
    external = var.exposed_ports["ldap"]
  }

  env = [
    "LDAP_ORGANISATION=VulnLab",
    "LDAP_DOMAIN=${var.lab_domain}",
    "LDAP_ADMIN_PASSWORD=${var.ldap_admin_password}",
    "LDAP_READONLY_USER=true",
    "LDAP_READONLY_USER_USERNAME=readonly",
    "LDAP_READONLY_USER_PASSWORD=readonly",
    "LDAP_TLS=false",
  ]

  volumes {
    volume_name    = docker_volume.ldap_data.name
    container_path = "/var/lib/ldap"
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

# ════════════════════════════════════════════════════════════════
#  HOST J — Network Infra  (BIND9 + Squid)
#  Config Flaw   : BIND9 unrestricted zone transfers
#  CVE-2020-11945: Squid digest auth cache poisoning
#  Networks: perimeter, infra_zone
# ════════════════════════════════════════════════════════════════

resource "docker_container" "host_j" {
  name     = "${var.project_name}-host-j"
  hostname = "host-j-infra"
  image    = docker_image.ubuntu.image_id

  networks_advanced { name = docker_network.perimeter.name }
  networks_advanced { name = docker_network.infra_zone.name }

  ports {
    internal = 53
    external = var.exposed_ports["dns"]
    protocol = "udp"
  }

  upload {
    content    = <<-SCRIPT
      #!/bin/bash
      set -e; export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq bind9 squid >/dev/null 2>&1
      # BIND9 — allow unrestricted zone transfers (Config Flaw)
      cat > /etc/bind/named.conf.options <<'EOF'
      options {
        directory "/var/cache/bind";
        recursion yes;
        allow-query { any; };
        allow-transfer { any; };
        allow-recursion { any; };
        forwarders { 8.8.8.8; 8.8.4.4; };
        dnssec-validation no;
        listen-on { any; };
      };
      EOF
      # Zone for the lab domain
      cat > /etc/bind/db.${var.lab_domain} <<'EOF'
      $TTL 604800
      @ IN SOA ns1.${var.lab_domain}. admin.${var.lab_domain}. (
              2024010101 604800 86400 2419200 604800 )
      @ IN NS  ns1.${var.lab_domain}.
      ns1     IN A 172.20.5.100
      host-a  IN A 172.20.0.10
      host-b  IN A 172.20.1.20
      host-c  IN A 172.20.0.30
      host-d  IN A 172.20.2.40
      host-e  IN A 172.20.2.50
      host-f  IN A 172.20.0.60
      host-g  IN A 172.20.3.70
      host-h  IN A 172.20.0.80
      host-i  IN A 172.20.4.90
      host-j  IN A 172.20.0.100
      EOF
      cat >> /etc/bind/named.conf.local <<'EOF'
      zone "${var.lab_domain}" {
        type master;
        file "/etc/bind/db.${var.lab_domain}";
        allow-transfer { any; };
      };
      EOF
      # Squid — permissive proxy (CVE-2020-11945 context)
      cat > /etc/squid/squid.conf <<'EOF'
      http_port 3128
      acl all src 0.0.0.0/0
      http_access allow all
      cache_dir ufs /var/spool/squid 100 16 256
      auth_param digest program /usr/lib/squid/digest_file_auth /etc/squid/passwords
      auth_param digest realm proxy
      auth_param digest nonce_garbage_interval 5 minutes
      auth_param digest nonce_max_duration 30 minutes
      EOF
      touch /etc/squid/passwords
      named -u bind
      squid -N &
      exec tail -f /dev/null
    SCRIPT
    file       = "/start.sh"
    executable = true
  }

  command = ["/bin/bash", "/start.sh"]

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
