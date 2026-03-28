# Exploring Vulnerable Infrastructure: A Terraform & Docker Playground

Welcome to the lab! 🚀 Over the last few days, I've built out this fully containerized, intentionally vulnerable network environment. This project uses Terraform and Docker to automatically spin up 11 different machines across a segmented network architecture.

Every single container here runs a different piece of vulnerable software – mostly compiled from actual source tarballs (like Apache, Samba, OpenLDAP, etc.) just to see how real-world CVEs behave in action. It's the perfect isolated playground to test lateral movement, pivoting, and classic exploits.

**⚠️ DISCLAIMER:** *This environment is intentionally packed with backdoor exploits and critical vulnerabilities. Do not deploy this on an internet-facing machine, or anywhere near production. Run it locally and tear it down when you're done.*

---

## 🗺️ The Network Layout

To make things interesting, the lab isn’t just a flat network. It's properly segmented into 6 security zones. The goal is to start on the outside and find a way into the core.

```text
                        ┌────────────────────────────────────────┐
                        │              PERIMETER ZONE            │
                        │   Attacker ── A ── C ── F ── H ── J    │
                        └────┬────────┬───┬───┬────┬────┬────────┘
                             │        │   │   │    │    │
                    ┌────────┘  ┌─────┘   │   │    │    └────────┐
                    ▼           ▼         ▼   ▼    ▼             ▼
              ┌──────────┐ ┌────────┐     │   │    │      ┌──────────┐
              │MAIL ZONE │ │INTERNAL│     │   │    │      │INFRA ZONE│
              │ A  B  E  │ │ C  D  E│     │   │    │      │  A  E  J │
              └──────────┘ └────────┘     │   │    │      └──────────┘
                                          │   │    │
                                    ┌─────┘   │    └─────┐
                                    ▼         ▼          ▼
                              ┌───────────┐ ┌────────────────┐
                              │ AUTH ZONE │ │  STORAGE ZONE  │
                              │A B C E F I│ │   E  F  G  H   │
                              └───────────┘ └────────────────┘
```

Notice **Host E (Backup)**? It acts as the bridge across the internal subnets. Compromise that box, and you basically hold the keys to the entire kingdom.

---

## 💻 Meet the Targets

Here's exactly what's inside each container and why it's dangerous:

| Host Name | Inside the Box | Built using | The Flaw | Exposed Ports |
|-----------|----------------|-------------|----------|---------------|
| **Attacker** | Kali Linux | Docker Hub | — | — |
| **Host A** (Mail GW) | OpenSMTPD 6.6.x | Apt source | **CVE-2020-7247** (RCE Auth Bypass) | 25 |
| **Host B** (Mail Store)| Postfix + Dovecot | Tarball + Apt | **CVE-2011-1720** (Memory Corruption) | 25, 110, 143 |
| **Host C** (FTP) | vsftpd 2.3.4 | Compiled from Source | **CVE-2011-2523** (The infamous Smiley Backdoor) | 2121 → 21 |
| **Host D** (Internal SMB)| Samba 3.5.0 | Compiled from Source | **CVE-2017-7494** ("SambaCry" RCE) | 139, 445 |
| **Host E** (Backup) | rsync 3.1.1 + SSH | Compiled from Source | **CVE-2014-9512** (Path Traversal) | 22, 873, 2049 |
| **Host F** (Cloud Sync) | OwnCloud 10.x | Tarball Extraction | **CVE-2023-49103** (phpinfo() Leak) | 8443 → 80 |
| **Host G** (Storage) | MinIO + MariaDB + Redis | Compiled via Go Builder | **CVE-2023-28432** (Info Disclosure) | 9000, 9001 |
| **Host H** (WebDAV) | Apache httpd 2.4.49| Compiled from Source | **CVE-2021-41773** (Path Traversal RCE) | 8082 → 80 |
| **Host I** (Directory) | OpenLDAP 2.4.18 | Compiled from Source | **Null DN / Anonymous Bind Bypass** | 3389 → 389 |
| **Host J** (Network Infra)| Squid 5.0.1 + BIND9 | Compiled from Source | **CVE-2020-11945** (Cache Poisoning) | 5354 → 53 |

---

## 🛠️ Getting the Lab Running

You'll need `Docker` and `Terraform` (v1.3.0+) installed on your machine. All source codes and setup files are included in the repository structure.

### 1. Fire It Up

Spinning up 11 custom-compiled machines naturally takes a minute or two on the first run. Pop open your terminal and run:

```bash
# Initialize terraform plugins
terraform init

# Build the images and spin up the architecture
terraform apply -auto-approve
```
*(The very first time you run this, Terraform will download compiling tools like Go, GCC, and Make into the Docker images. Grab a coffee! Afterwards, Docker reuses its cache and builds take seconds.)*

### 2. Verify Services & Access Points

Once Terraform finishes, you should have 11 containers running. You can check their status using Docker:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Here is exactly how to check and connect to every single vulnerable service in the lab.

#### 🌐 Web Interfaces (Accessible from your Host browser)
* **Host F (OwnCloud):** `http://localhost:8443` (Default login: `admin` / `admin`)
* **Host G (MinIO Console):** `http://localhost:9001` (Login: `minioadmin` / `minioadmin123`)
* **Host G (MinIO API):** `http://localhost:9000/minio/health/live` (Should return 200 OK)
* **Host H (Apache httpd):** `http://localhost:8082` (Will show "It works!" or directory listing)

#### 💻 Network Protocols (Accessible from your Host terminal)
* **Host C (vsftpd FTP):** `ftp localhost 2121` (or `nc localhost 2121`)
  * *Try sending `USER backdoor:)` to see what happens!*
* **Host I (OpenLDAP):** 
  * Query the directory anonymously: `ldapsearch -x -H ldap://localhost:3389 -b "dc=vuln-lab,dc=local" "(objectClass=*)"`
* **Host J (DNS):**
  * Check if BIND9 is answering queries: `dig @localhost -p 5354 google.com`

#### 🥷 The Attacker Entry Point
Most of the interior servers (like Samba, Rsync, SMTP) are deliberately **not mapped to your localhost**. To interact with them, you must jump into the Kali Linux "Attacker" container, which acts as your jumpbox physically wired into the lab's perimeter.

**To drop into the attacker shell:**
```bash
docker exec -it vuln-lab-attacker bash
```

Once inside `vuln-lab-attacker`, you can ping or run tools against the interior services using their Docker network hostnames:
* **Check Host A (OpenSMTPD):** `nc -v vuln-lab-host-a 25`
* **Check Host B (Postfix/Dovecot):** `nc -v vuln-lab-host-b 110` (or ports 25, 143)
* **Check Host D (Samba):** `smbclient -L //vuln-lab-host-d/ -N`
* **Check Host E (Rsync/SSH):** `rsync vuln-lab-host-e::`

### 3. Firing the Exploit Scripts

Some hosts have pre-packaged exploit scripts located in their respective source folders. When Terraform builds the images, it copies these exploits directly into the `/exploits/` directory of the target container.

However, the realistic way to use them is to run them *from the attacker container*. 
For example, to run the Apache Path Traversal exploit:
1. Copy the script from your local machine to the attacker:
   ```bash
   docker cp WebDAV/httpd/50383.sh vuln-lab-attacker:/root/
   ```
2. Run it against Host H from the attacker shell:
   ```bash
   docker exec -it vuln-lab-attacker bash
   chmod +x /root/50383.sh
   /root/50383.sh vuln-lab-host-h
   ```

### 4. Shutting Down

When you're finished experimenting, safely tear down the infrastructure to free up memory:
```bash
terraform destroy -auto-approve
```

---

## 🎯 Exploit Scripts Included

I threw in the Python and Ruby PoCs for a few of the more annoying exploits so you don't have to hunt them down. You can find them right inside the `/exploits/` folder of the respective host's container:

* **Host A:** `MailGW/opensmtpd/47984.py`
* **Host C:** `FTP/vsftpd/17491.rb` (Metasploit)
* **Host D:** `SMB/samba/42060.py`
* **Host H:** `WebDAV/httpd/50383.sh`

---

## ⚔️ Fun Attack Paths to Try

If you're wondering where to start, try these combinations:

1. **The Classic Backdoor:** Hit **Host C (FTP)** with the smiley face trigger, pop a shell, and pivot aggressively to the interior networks.
2. **The Open Book:** Pivot from Host C over to **Host I (LDAP)**. Connect anonymously and watch it dump every password on the network.
3. **The Web Entry:** Exploit the path traversal on **Host H (Apache)**, find sensitive credentials, and pivot to **Host E (Backup)**.
4. **The Complete Takeover:** Since Host E bridges every single zone, once you compromise it with the SambaCry or Rsync traversal, you have God-mode access over the entire lab.

Happy hacking! Have fun digging through the configs and watching these old CVEs break things! 
