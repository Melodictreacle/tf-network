# Vulnerable Network Lab — Terraform + Docker

A multi-host vulnerable network lab deployed via Terraform on Docker. Each host runs a real service compiled from source (or extracted from its original release tarball) with known CVEs and misconfigurations for security testing and learning.

---

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              PERIMETER ZONE             │
                        │   Attacker ── A ── C ── F ── H ── J    │
                        └────┬────────┬───┬───┬────┬────┬────────┘
                             │        │   │   │    │    │
                    ┌────────┘  ┌─────┘   │   │    │    └────────┐
                    ▼           ▼          │   │    │             ▼
              ┌──────────┐ ┌────────┐     │   │    │      ┌──────────┐
              │MAIL ZONE │ │INTERNAL│     │   │    │      │INFRA ZONE│
              │ A  B  E  │ │ C D E  │     │   │    │      │  A  E  J │
              └──────────┘ └────────┘     │   │    │      └──────────┘
                                          │   │    │
                                    ┌─────┘   │    └─────┐
                                    ▼         ▼          ▼
                              ┌──────────┐ ┌────────────────┐
                              │AUTH ZONE │ │  STORAGE ZONE  │
                              │A B C E F I│ │   E F G H     │
                              └──────────┘ └────────────────┘
```

**11 containers** across **6 network zones** — segmented by function, bridged by Host E (Backup).

---

## Hosts & Vulnerabilities

| Host | Name | Service | Built From | CVE / Flaw | Exposed Port |
|------|------|---------|-----------|------------|--------------|
| **Attacker** | Kali Linux | — | Docker Hub | — | — |
| **A** | Mail Gateway | OpenSMTPD 6.6.x | `opensmtpd-6.6.1p1.tar.gz` | **CVE-2020-7247** — RCE auth bypass | 25 |
| **B** | Mail Store | Postfix + Dovecot | `postfix-2.5.6-vda-ng.patch.gz` | **CVE-2011-1720** — mem corruption DoS | 25, 110, 143 |
| **C** | Legacy FTP | vsftpd 2.3.4 | `vsftpd-2.3.4.tar.gz` | **CVE-2011-2523** — backdoor RCE (port 6200) | 2121 → 21 |
| **D** | Internal SMB | Samba 3.5.0 | `samba-3.5.0.tar.gz` | **CVE-2017-7494** — SambaCry RCE | 139, 445 |
| **E** | Backup Server | rsync 3.1.1 + SSH + NFS | `rsync-3.1.1.tar.gz` | **CVE-2014-9512** — path traversal write | 22, 873, 2049 |
| **F** | Cloud Sync | OwnCloud 10.x | `owncloud-complete-20230313.tar.bz2` | **CVE-2023-49103** — phpinfo leak | 8443 → 80 |
| **G** | Storage | MinIO + MariaDB + Redis | `minio-RELEASE.2023-03-13.tar.gz` | **CVE-2023-28432** — env var info disclosure | 9000, 9001 |
| **H** | WebDAV Share | Apache httpd 2.4.49 | `httpd-2.4.49.tar.gz` | **CVE-2021-41773** — path traversal RCE | 8082 → 80 |
| **I** | Directory Auth | OpenLDAP 2.4.18 | `openldap-2.4.18.tgz` | **Config Flaw** — null DN auth bypass | 3389 → 389 |
| **J** | Net Infra | Squid 5.0.1 + BIND9 | `squid-SQUID_5_0_1.tar.gz` | **CVE-2020-11945** — cache poisoning | 5354 → 53 |

---

## Exploit Scripts Included

| File | Target | Description |
|------|--------|-------------|
| `MailGW/opensmtpd/47984.py` | Host A | OpenSMTPD RCE exploit (Python) |
| `FTP/vsftpd/17491.rb` | Host C | vsftpd 2.3.4 backdoor exploit (Metasploit) |
| `SMB/samba/42060.py` | Host D | SambaCry RCE exploit (Python) |
| `WebDAV/httpd/50383.sh` | Host H | Apache path traversal PoC (Bash) |

Exploit scripts are placed at `/exploits/` inside each host container.

---

## Prerequisites

- **Docker Desktop** (Windows/macOS) or Docker Engine (Linux)
- **Terraform** ≥ 1.3.0
- ~6 GB disk space for Docker images
- ~4 GB RAM recommended

---

## Quick Start

### 1. Clone & Initialize

```bash
git clone <repo-url>
cd tf-network
terraform init
```

### 2. Deploy

```bash
terraform apply -auto-approve
```

> **First run takes ~5 minutes** — Terraform builds all 10 Docker images from source (compiles vsftpd, Samba, rsync, Apache httpd, OpenLDAP, Squid, MinIO from their tarballs).
>
> Subsequent runs are fast (images are cached).

### 3. Access

| Service | URL |
|---------|-----|
| OwnCloud | http://localhost:8443 (admin / admin) |
| MinIO Console | http://localhost:9001 (minioadmin / minioadmin123) |
| Apache httpd | http://localhost:8082 |
| FTP (vsftpd) | `ftp localhost 2121` |
| LDAP | `ldapsearch -x -H ldap://localhost:3389` |
| DNS | `dig @localhost -p 5354 ANY` |

### 4. Enter the Attacker

```bash
docker exec -it vuln-lab-attacker /bin/bash
```

From inside the attacker container, all hosts are reachable via their hostnames on the perimeter network.

### 5. Tear Down

```bash
terraform destroy -auto-approve
```

---

## Project Structure

```
tf-network/
├── main.tf              # Provider, images (build blocks), networks, volumes
├── hosts.tf             # Container definitions for all 11 hosts
├── variables.tf         # Configurable ports, project name, Docker host
├── outputs.tf           # Access URLs, container names, attack path matrix
│
├── MailGW/              # Host A — OpenSMTPD
│   ├── Dockerfile
│   └── opensmtpd/
│       ├── opensmtpd-6.6.1p1.tar.gz
│       └── 47984.py          # CVE-2020-7247 exploit
│
├── MailSt/              # Host B — Postfix + Dovecot
│   ├── Dockerfile
│   └── postfix/
│       └── postfix-2.5.6-vda-ng.patch.gz
│
├── FTP/                 # Host C — vsftpd 2.3.4
│   ├── Dockerfile
│   └── vsftpd/
│       ├── vsftpd-2.3.4.tar.gz
│       └── 17491.rb          # CVE-2011-2523 exploit
│
├── SMB/                 # Host D — Samba 3.5.0
│   ├── Dockerfile
│   └── samba/
│       ├── samba-3.5.0.tar.gz
│       └── 42060.py          # CVE-2017-7494 exploit
│
├── Backup/              # Host E — rsync + SSH + NFS
│   ├── Dockerfile
│   └── rsync/
│       └── rsync-3.1.1.tar.gz
│
├── Cloud/               # Host F — OwnCloud
│   ├── Dockerfile
│   ├── start.sh              # Auto-configures DB connection to Host G
│   └── Owncloud/
│       └── owncloud-complete-20230313.tar.bz2
│
├── ObjSto/              # Host G — MinIO + MariaDB + Redis
│   ├── Dockerfile            # Multi-stage build (Go compilation)
│   ├── start.sh              # Starts MariaDB, Redis, MinIO
│   └── minio/
│       └── minio-RELEASE.2023-03-13.tar.gz
│
├── WebDAV/              # Host H — Apache httpd 2.4.49
│   ├── Dockerfile
│   └── httpd/
│       ├── httpd-2.4.49.tar.gz
│       └── 50383.sh          # CVE-2021-41773 exploit
│
├── DirAut/              # Host I — OpenLDAP 2.4.18
│   ├── Dockerfile
│   └── openldap/
│       └── openldap-2.4.18.tgz
│
└── NetInf/              # Host J — Squid 5.0.1 + BIND9
    ├── Dockerfile
    ├── start.sh
    └── squid/
        └── squid-SQUID_5_0_1.tar.gz
```

---

## Network Zones

| Zone | Subnet | Hosts | Purpose |
|------|--------|-------|---------|
| `perimeter` | 172.20.0.0/24 | Attacker, A, C, F, H, J | DMZ / attacker-facing |
| `mail_zone` | 172.20.1.0/24 | A, B, E | Mail relay path |
| `internal_zone` | 172.20.2.0/24 | C, D, E | FTP & SMB segment |
| `storage_zone` | 172.20.3.0/24 | E, F, G, H | Storage & sync |
| `auth_zone` | 172.20.4.0/24 | A, B, C, E, F, I | LDAP authentication |
| `infra_zone` | 172.20.5.0/24 | A, E, J | DNS & network infra |

Host **E (Backup)** is present in all internal zones — compromising it grants access to every segment.

---

## Attack Paths

```
Attacker → Host A (SMTP)     → Host B (relay)  → Host I (LDAP)
Attacker → Host C (FTP)      → Host D (SMB)    → Host E (Backup) → ALL
Attacker → Host F (OwnCloud) → Host G (MinIO)  → Host E (rsync)
Attacker → Host H (WebDAV)   → Host E (rsync)
Attacker → Host J (DNS)      → Host A (infra)  → Host E (Backup)
```

---

## Configuration

Edit `variables.tf` to customize:

```hcl
variable "project_name"  { default = "vuln-lab" }
variable "docker_host"   { default = "npipe:////./pipe/docker_engine" }  # Windows
# variable "docker_host" { default = "unix:///var/run/docker.sock" }     # Linux/macOS

variable "exposed_ports" {
  default = {
    ftp       = 2121
    owncloud  = 8443
    minio_api = 9000
    minio_ui  = 9001
    httpd     = 8082
    ldap      = 3389
    dns       = 5354
  }
}
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Port conflict on 5354 | Change `dns` port in `variables.tf` |
| Image build fails | Run `docker build --no-cache ./<folder>` to see full errors |
| Container exits immediately | Check logs: `docker logs vuln-lab-host-<x>` |
| OwnCloud can't connect to DB | Ensure Host G started first (Terraform handles ordering via `depends_on`) |
| MinIO build is slow | First build downloads Go + compiles (~3 min). Cached after that. |

---

## Disclaimer

> **⚠️ For educational and authorized security testing only.**
>
> This lab contains intentionally vulnerable software. Do **not** expose these containers to the internet or use them in production. The author is not responsible for misuse.

---

## License

This project is provided as-is for educational purposes.
