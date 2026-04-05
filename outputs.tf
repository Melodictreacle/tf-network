# ==============================================================
# outputs.tf - Lab access info & attack path reference
# ==============================================================

# -- Network Zones
output "network_zones" {
  description = "Docker network zones (DMZ + 4 internal)"
  value = {
    dmz             = docker_network.dmz.name
    net_1_perimeter = docker_network.net_1.name
    net_2_mail_auth = docker_network.net_2.name
    net_3_internal  = docker_network.net_3.name
    net_4_storage   = docker_network.net_4.name
  }
}

# -- Container Names
output "containers" {
  description = "All lab containers"
  value = {
    attacker                = docker_container.attacker.name
    "website (VulnCorp)"    = docker_container.website.name
    "firewall (Gateway)"    = docker_container.firewall.name
    "host_a (Mail Gateway)" = docker_container.host_a.name
    "host_b (Mail Store)"   = docker_container.host_b.name
    "host_c (Legacy FTP)"   = docker_container.host_c.name
    "host_d (Internal SMB)" = docker_container.host_d.name
    "host_e (Backup)"       = docker_container.host_e.name
    "host_f (Cloud Sync)"   = docker_container.host_f.name
    "host_g (Storage)"      = docker_container.host_g.name
    "host_h (WebDAV)"       = docker_container.host_h.name
    "host_i (Directory)"    = docker_container.host_i.name
    "host_j (Net Infra)"    = docker_container.host_j.name
  }
}

# -- Attacker Access
output "attacker_shell" {
  description = "Command to enter the attacker container"
  value       = "docker exec -it ${var.project_name}-attacker /bin/bash"
}

# -- Host-accessible URLs
output "management_urls" {
  description = "Services exposed to the Docker host"
  value = {
    "VulnCorp Website"       = "http://localhost:${var.exposed_ports["website"]}"
  }
}

# -- Static IP Quick Reference
output "static_ips" {
  description = "Static IP assignments per host per network"
  value = <<-IPS

    ┌──────────────────────────────────────────────────────────────────────────────┐
    │                         STATIC IP ASSIGNMENTS                              │
    ├──────────┬────────────┬──────────────┬──────────────┬──────────┬────────────┤
    │  Host    │  DMZ       │  net_1       │  net_2       │  net_3   │  net_4     │
    │          │  10.10.0.x │  10.10.1.x   │  10.10.2.x   │ 10.10.3.x│ 10.10.4.x │
    ├──────────┼────────────┼──────────────┼──────────────┼──────────┼────────────┤
    │ Attacker │  .10       │     —        │     —        │    —     │    —       │
    │ Website  │  .2        │     —        │     —        │    —     │    —       │
    │ Firewall │  .3        │    .3        │    .3        │   .3     │   .3       │
    │ Host A   │   —        │   .11        │   .11        │    —     │    —       │
    │ Host B   │   —        │    —         │   .12        │    —     │    —       │
    │ Host C   │   —        │   .13        │    —         │   .13    │    —       │
    │ Host D   │   —        │    —         │    —         │   .14    │    —       │
    │ Host E   │   —        │   .15        │   .15        │   .15    │   .15      │
    │ Host F   │   —        │   .16        │    —         │    —     │   .16      │
    │ Host G   │   —        │    —         │    —         │    —     │   .17      │
    │ Host H   │   —        │   .18        │    —         │    —     │   .18      │
    │ Host I   │   —        │    —         │   .19        │    —     │    —       │
    │ Host J   │   —        │   .20        │    —         │    —     │    —       │
    └──────────┴────────────┴──────────────┴──────────────┴──────────┴────────────┘
  IPS
}

# -- Attack Path Quick Reference
output "attack_paths" {
  description = "Network attack paths across DMZ + 4 internal networks"
  value = <<-MATRIX

    +-----------------------------------------------------------------------------+
    |                 NETWORK ATTACK PATHS (DMZ + 4 Internal)                     |
    +-----------------------------------------------------------------------------+
    |  STEP 1: Break into the DMZ                                                 |
    |  Attacker -> Website (http)     /.maintenance.php backdoor                  |
    |  Attacker -> Firewall (ssh)     root:toor weak credentials                  |
    +-----------------------------------------------------------------------------+
    |  STEP 2: Pivot from Firewall into internal networks                         |
    |  Firewall is on ALL 5 networks — once compromised, reach anything:          |
    |    -> net_1: Host A (.11), C (.13), E (.15), F (.16), H (.18), J (.20)      |
    |    -> net_2: Host A (.11), B (.12), E (.15), I (.19)                        |
    |    -> net_3: Host C (.13), D (.14), E (.15)                                 |
    |    -> net_4: Host E (.15), F (.16), G (.17), H (.18)                        |
    +-----------------------------------------------------------------------------+
    |  STEP 3: Lateral movement inside internal networks                          |
    |  Host A -> Host B (smtp)      via net_2                                     |
    |  Host A -> Host I (ldap)      via net_2                                     |
    |  Host C -> Host D (smb)       via net_3                                     |
    |  Host C -> Host E (nfs)       via net_3                                     |
    |  Host F -> Host G (http)      via net_4                                     |
    |  Host H -> Host E (rsync)     via net_4                                     |
    +-----------------------------------------------------------------------------+
    |  Host E -> ALL internal hosts — bridges net_1/2/3/4 (God-mode)             |
    +-----------------------------------------------------------------------------+
  MATRIX
}
