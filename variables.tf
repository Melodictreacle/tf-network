# ==============================================================
# variables.tf — Vulnerability Lab (Docker)
# ==============================================================

variable "docker_host" {
  description = "Docker daemon socket"
  type        = string
  default     = "npipe:////./pipe/docker_engine"
}

variable "project_name" {
  description = "Prefix for all resources"
  type        = string
  default     = "vuln-lab"
}

variable "lab_domain" {
  description = "Internal DNS domain for the lab"
  type        = string
  default     = "vuln-lab.local"
}

# ── Image versions (pinned to vulnerable releases) ───────────

variable "owncloud_version" {
  description = "OwnCloud version (CVE-2023-49103)"
  type        = string
  default     = "10.13"
}

variable "minio_version" {
  description = "MinIO version (CVE-2023-28432)"
  type        = string
  default     = "RELEASE.2023-03-13T19-46-17Z"
}

variable "httpd_version" {
  description = "Apache httpd version (CVE-2021-41773)"
  type        = string
  default     = "2.4.49"
}

variable "openldap_version" {
  description = "OpenLDAP version (null DN auth bypass)"
  type        = string
  default     = "1.5.0"
}

# ── Credentials ───────────────────────────────────────────────

variable "ldap_admin_password" {
  description = "OpenLDAP admin password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "minio_root_user" {
  description = "MinIO root user"
  type        = string
  default     = "minioadmin"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  default     = "minioadmin123"
  sensitive   = true
}

# ── Host port mappings (host → container) ─────────────────────

variable "exposed_ports" {
  description = "Ports exposed to the Docker host for management access"
  type        = map(number)
  default = {
    website   = 8888   # DMZ   - VulnCorp Website
  }
}
