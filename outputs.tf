# ==============================================================
# outputs.tf - Lab access info & attack path reference
# ==============================================================

# -- Network Zones
output "network_zones" {
  description = "Docker network zones"
  value = {
    perimeter     = docker_network.perimeter.name
    mail_zone     = docker_network.mail_zone.name
    internal_zone = docker_network.internal_zone.name
    storage_zone  = docker_network.storage_zone.name
    auth_zone     = docker_network.auth_zone.name
    infra_zone    = docker_network.infra_zone.name
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
    "Host F - OwnCloud"     = "http://localhost:${var.exposed_ports["owncloud"]}"
    "Host G - MinIO Console" = "http://localhost:${var.exposed_ports["minio_ui"]}"
    "Host G - MinIO API"     = "http://localhost:${var.exposed_ports["minio_api"]}"
    "Host H - Apache httpd"  = "http://localhost:${var.exposed_ports["httpd"]}"
  }
}

# -- Attack Path Quick Reference
output "attack_paths" {
  description = "Network attack paths from the matrix"
  value = <<-MATRIX

    +-----------------------------------------------------------------------------+
    |                        NETWORK ATTACK PATHS                                 |
    |  Source -> Destination (protocol)                                            |
    +-----------------------------------------------------------------------------+
    |  Attacker -> Host A (smtp)   Host A (smtp)                                  |
    |  Attacker -> Host C (ftp)    Host C (ftp)                                   |
    |  Attacker -> Host F (https)  Host F (owncloud)                              |
    |  Attacker -> Host H (https)  Host H (httpd path traversal)                  |
    |  Attacker -> Host J (dns)    Host J (zone transfer)                         |
    +-----------------------------------------------------------------------------+
    |  Host A -> Host B (smtp)    |  Host C -> Host E (nfs)                       |
    |  Host A -> Host I (ldap)    |  Host C -> Host I (ldap)                      |
    |  Host A -> Host J (dns)     |  Host D -> Host E (nfs)                       |
    +-----------------------------------------------------------------------------+
    |  Host B -> Host I (ldap)    |  Host F -> Host E (rsync)                     |
    |                             |  Host F -> Host G (http)                      |
    |  Host H -> Host E (rsync)   |  Host F -> Host I (ldap)                     |
    +-----------------------------------------------------------------------------+
    |  Host E -> ALL hosts (ssh)  - Backup server bridges every zone              |
    +-----------------------------------------------------------------------------+
  MATRIX
}
