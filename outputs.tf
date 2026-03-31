# ==============================================================
# outputs.tf - Lab access info & attack path reference
# ==============================================================

# -- Network Zones
output "network_zones" {
  description = "Docker network zones (4 separate networks)"
  value = {
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
    "Host F - OwnCloud"      = "http://localhost:${var.exposed_ports["owncloud"]}"
    "Host G - MinIO Console"  = "http://localhost:${var.exposed_ports["minio_ui"]}"
    "Host G - MinIO API"      = "http://localhost:${var.exposed_ports["minio_api"]}"
    "Host H - Apache httpd"   = "http://localhost:${var.exposed_ports["httpd"]}"
  }
}

# -- Static IP Quick Reference
output "static_ips" {
  description = "Static IP assignments per host per network"
  value = <<-IPS

    ┌─────────────────────────────────────────────────────────────────────┐
    │                    STATIC IP ASSIGNMENTS                           │
    ├──────────┬──────────────┬──────────────┬──────────────┬────────────┤
    │  Host    │  net_1       │  net_2       │  net_3       │  net_4     │
    │          │  10.10.1.x   │  10.10.2.x   │  10.10.3.x   │ 10.10.4.x │
    ├──────────┼──────────────┼──────────────┼──────────────┼────────────┤
    │ Attacker │  .10         │     —        │     —        │    —       │
    │ Host A   │  .11         │    .11       │     —        │    —       │
    │ Host B   │   —          │    .12       │     —        │    —       │
    │ Host C   │  .13         │     —        │    .13       │    —       │
    │ Host D   │   —          │     —        │    .14       │    —       │
    │ Host E   │  .15         │    .15       │    .15       │   .15      │
    │ Host F   │  .16         │     —        │     —        │   .16      │
    │ Host G   │   —          │     —        │     —        │   .17      │
    │ Host H   │  .18         │     —        │     —        │   .18      │
    │ Host I   │   —          │    .19       │     —        │    —       │
    │ Host J   │  .20         │     —        │     —        │    —       │
    └──────────┴──────────────┴──────────────┴──────────────┴────────────┘
  IPS
}

# -- Attack Path Quick Reference
output "attack_paths" {
  description = "Network attack paths across the 4 networks"
  value = <<-MATRIX

    +-----------------------------------------------------------------------------+
    |                   NETWORK ATTACK PATHS (4-Network Layout)                   |
    +-----------------------------------------------------------------------------+
    |  net_1 (Perimeter)  Attacker can reach: A, C, E, F, H, J                    |
    +-----------------------------------------------------------------------------+
    |  Attacker -> Host A (smtp)   via net_1                                      |
    |  Attacker -> Host C (ftp)    via net_1                                      |
    |  Attacker -> Host F (https)  via net_1                                      |
    |  Attacker -> Host H (httpd)  via net_1                                      |
    |  Attacker -> Host J (dns)    via net_1                                      |
    |  Attacker -> Host E (rsync)  via net_1                                      |
    +-----------------------------------------------------------------------------+
    |  net_2 (Mail & Auth)  A <-> B, A <-> I, B <-> I, E <-> all                  |
    |  Host A -> Host B (smtp)    via net_2                                       |
    |  Host A -> Host I (ldap)    via net_2                                       |
    |  Host B -> Host I (ldap)    via net_2                                       |
    +-----------------------------------------------------------------------------+
    |  net_3 (Internal)  C <-> D, C <-> E, D <-> E                                |
    |  Host C -> Host D (smb)     via net_3                                       |
    |  Host C -> Host E (nfs)     via net_3                                       |
    |  Host D -> Host E (nfs)     via net_3                                       |
    +-----------------------------------------------------------------------------+
    |  net_4 (Storage)  E <-> F, E <-> G, E <-> H, F <-> G, F <-> H, G <-> H     |
    |  Host F -> Host G (http)    via net_4                                       |
    |  Host F -> Host E (rsync)   via net_4                                       |
    |  Host H -> Host E (rsync)   via net_4                                       |
    +-----------------------------------------------------------------------------+
    |  Host E -> ALL hosts — bridges every network (God-mode pivot)               |
    +-----------------------------------------------------------------------------+
  MATRIX
}
