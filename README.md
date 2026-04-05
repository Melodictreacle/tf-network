# Exploring Vulnerable Infrastructure: A Terraform & Docker Playground

Welcome to the lab! 🚀 Over the last few days, I've built out this fully containerized, intentionally vulnerable network environment. This project uses Terraform and Docker to automatically spin up a completely segmented, realistically-architected enterprise network containing multiple vulnerable services.

Every single container here runs a different piece of vulnerable software – either compiled from actual source tarballs (like Apache, Samba, OpenLDAP, etc.) or configured with intentional flaws. It's the perfect isolated playground to test lateral movement, pivoting, and classic exploits.

**⚠️ DISCLAIMER:** *This environment is intentionally packed with backdoor exploits and critical vulnerabilities. Do not deploy this on an internet-facing machine, or anywhere near production. Run it locally and tear it down when you're done.*

---

## 🗺️ The Network Layout

To make things realistic, the lab is strictly segmented into a **DMZ and 4 internal networks**. 
The Attacker starts on the outside (the DMZ) and must find a way to pivot through the firewall or public-facing website to reach the internal core.

```text
    INTERNET (Attacker: 10.10.0.10)
         │
    ┌────▼──────────────────────────────────────┐
    │         DMZ (10.10.0.0/24)                │
    │   Attacker .10  │  Website .2             │
    │                 │  Firewall .3             │
    └─────────────────┼─────────────────────────┘
                      │ Firewall bridges all 4 networks
        ┌─────────────┼──────────────┐
        │             │              │
   ┌────▼────┐  ┌─────▼────┐  ┌─────▼────┐  ┌──────────┐
   │ net_1   │  │  net_2   │  │  net_3   │  │  net_4   │
   │Perimeter│  │Mail/Auth │  │Internal  │  │ Storage  │
   │10.10.1.x│  │10.10.2.x │  │10.10.3.x │  │10.10.4.x │
   └─────────┘  └──────────┘  └──────────┘  └──────────┘
    A,C,E,       A,B,E,I        C,D,E         E,F,G,H
    F,H,J
```

Notice **Host E (Backup)**? It acts as the bridge across all internal subnets. Compromise that box, and you basically hold the keys to the entire internal kingdom. But first, you have to get past the DMZ.

---

## 💻 Meet the Targets

Here's exactly what's inside each container and why it's dangerous:

### Perimeter / Entry Points
| Host Name | Inside the Box | The Flaw | Exposed Ports |
|-----------|----------------|----------|---------------|
| **Attacker** | Kali Linux | — (Your machine) | — |
| **Website** | Apache + PHP 7.4 | **Hidden Backdoor** (Command Injection) | 8888 → 80 |
| **Firewall** | Alpine + OpenSSH | **Config Flaw** (Weak `root:toor` creds) | 22 |

### Internal Services
| Host Name | Inside the Box | The Flaw |
|-----------|----------------|----------|
| **Host A** (Mail GW) | OpenSMTPD 6.6.x | **CVE-2020-7247** (RCE Auth Bypass) |
| **Host B** (Mail Store)| Postfix + Dovecot | **CVE-2011-1720** (Memory Corruption) & Config Flaw |
| **Host C** (FTP) | vsftpd 2.3.4 | **CVE-2011-2523** (The infamous Smiley Backdoor) |
| **Host D** (Internal SMB)| Samba 3.5.0 | **CVE-2017-7494** ("SambaCry" RCE) |
| **Host E** (Backup) | rsync 3.1.1 + SSH | **CVE-2014-9512** (Path Traversal) & NFS root_squash Flaw |
| **Host F** (Cloud Sync) | OwnCloud 10.x | **CVE-2023-49103** (phpinfo() Leak) |
| **Host G** (Storage) | MinIO + MariaDB + Redis | **CVE-2023-28432** (Info Disclosure) |
| **Host H** (WebDAV) | Apache httpd 2.4.49| **CVE-2021-41773** (Path Traversal RCE) |
| **Host I** (Directory) | OpenLDAP 2.4.18 | **Null DN / Anonymous Bind Bypass** |
| **Host J** (Network Infra)| Squid 5.0.1 + BIND9 | **CVE-2020-11945** (Cache Poisoning) |

---

## 🛠️ Getting the Lab Running

You'll need `Docker` and `Terraform` (v1.3.0+) installed on your machine. All source code and setup files are included in the repository structure.

### 1. Fire It Up

Pop open your terminal and run:

```bash
# Initialize terraform plugins
terraform init

# Build the images and spin up the architecture
terraform apply -auto-approve
```
*(The first run will download base images and compile tools like Go, GCC, and Make into the Docker images. Grab a coffee! Afterwards, Docker reuses its cache and builds take seconds.)*

### 2. Verify Services & Access Points

#### 🌐 Web Interfaces (Accessible from your Host browser)
* **VulnCorp Website (DMZ):** `http://localhost:8888`

*(Note: In "Hardcore Mode", all internal web interfaces like OwnCloud and MinIO are deliberately isolated from your host browser. You must pivot through the DMZ to access them!)*

#### 🥷 The Attacker Entry Point

Almost all servers are deeply hidden inside the segmented internal networks (`10.10.x.0/24`). To interact with them, you must jump into the Kali Linux "Attacker" container, which sits strictly in the **DMZ (`10.10.0.0/24`)**.

**To drop into the attacker shell:**
```bash
docker exec -it vuln-lab-attacker bash
```

Once inside `vuln-lab-attacker`, you will notice you **cannot ping internal hosts** like Host A (`10.10.1.11`). You can only see the DMZ hosts: the VulnCorp Website (`10.10.0.2`) and the Firewall (`10.10.0.3`). 

**You must compromise a DMZ host and pivot.**

---

## 🏫 Real-World Enterprise Concepts Demonstrated

This lab simulates real enterprise architecture. As you play, keep these core concepts in mind:

### 1. The Three-Legged Firewall
Notice how the firewall acts as the absolute center of the network. A real enterprise uses a "Three-Legged Firewall" architecture:
* **Leg 1 (Untrusted):** The public Internet.
* **Leg 2 (Semi-Trusted):** The **DMZ** (where public-facing web servers live).
* **Leg 3 (Trusted):** The **Internal Networks** (where databases and employee laptops are).
If a real firewall allows unrestricted traffic between these legs, it defeats the purpose of the firewall. 

### 2. Egress Traffic Flaws
In this lab, the firewall is dangerously misconfigured: it allows all outgoing (Egress) traffic from the internal networks to the outside. Hackers love this! If you compromise an internal server, you can tell it to open a "Reverse Shell" back to your attacker machine. Because the firewall trusts all outgoing traffic blindly, it lets the connection right through! *Modern "Zero Trust" networks fix this by aggressively blocking outgoing traffic too.*

### 3. Pivoting via Proxychains / SSH Tunnels
To hack the internal servers, you must route your packets *through* the firewall. 
For example, if you compromise the Firewall (`10.10.0.3`) by finding its weak OpenSSH password (`root:toor`), you can set up a local proxy tunnel:
`ssh -D 9050 root@10.10.0.3`
You can now use tools like `proxychains` on your attacker machine to force all your nmap scans and curl requests to travel through the firewall gateway and into the internal networks!

---

## ⚔️ Fun Attack Paths to Try

If you're wondering where to start, here is the intended attack progression:

### Phase 1: Break into the DMZ
1. **The Web Backdoor**: Investigate the VulnCorp Website (`http://10.10.0.2` from the attacker container). Can you find the hidden `.maintenance.php` backdoor? 
2. **The Lazy Admin**: The firewall container (`10.10.0.3`) has an OpenSSH service running. Maybe they left the default `root:toor` password intact?

### Phase 2: Pivot to Internal Subnets
Once you compromise the Firewall (which bridges the DMZ to `net_1`, `net_2`, `net_3`, and `net_4`), you can use it as a jumpbox.
```bash
# Example: ssh into the compromised firewall from the attacker machine
ssh root@10.10.0.3
```

From the firewall, you now have direct line-of-sight to the internal hosts.
* **Scan net_1:** `ping 10.10.1.11` (Host A), `ping 10.10.1.13` (Host C)
* **Scan net_3:** `ping 10.10.3.14` (Host D)

### Phase 3: Lateral Movement
1. **The Classic FTP Backdoor:** Found Host C on `net_1` or `net_3`? Hit it with the smiley face trigger (`USER backdoor:)`), pop a shell, and pivot further.
2. **The Open Book:** Reach Host I (LDAP) on `net_2`. Connect anonymously and watch it dump every password on the network.
3. **The Complete Takeover:** Your ultimate goal is **Host E (Backup)** at `.15`. It bridges all 4 internal networks. Sploit its SambaCry or Rsync traversal vulnerability, and you have God-mode access over the entire internal environment.

---

## 🎯 Exploit Scripts Included

I threw in the Python and Ruby PoCs for a few of the more annoying older exploits so you don't have to hunt them down. You can find them right inside the `/exploits/` folder of the respective host's container:

* **Host A:** `MailGW/opensmtpd/47984.py`
* **Host C:** `FTP/vsftpd/17491.rb` (Metasploit)
* **Host D:** `SMB/samba/42060.py`
* **Host H:** `WebDAV/httpd/50383.sh`

*(Copy them from your host to the attacker container via `docker cp` to use them).*

---

### Shutting Down

When you're finished experimenting, safely tear down the infrastructure to free up memory:
```bash
terraform destroy -auto-approve
```

Happy hacking! Have fun pivoting through the DMZ and watching these CVEs break things!
