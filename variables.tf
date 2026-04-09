# ==============================================================
# variables.tf — Vulnerability Lab (VMware Workstation)
# ==============================================================

variable "vmw_user" {
  description = "VMware Workstation REST API Username"
  type        = string
  default     = "admin"
}

variable "vmw_password" {
  description = "VMware Workstation REST API Password"
  type        = string
  default     = "password"
}

variable "vmw_url" {
  description = "VMware Workstation REST API URL (usually http://127.0.0.1:8697/api)"
  type        = string
  default     = "http://127.0.0.1:8697/api"
}

variable "base_vm_path" {
  description = "Absolute path to your clean Ubuntu 20.04 base .vmx file"
  type        = string
  # Example: "C:\\Virtual Machines\\Ubuntu-20.04-Base\\Ubuntu-20.04-Base.vmx"
  default     = "C:\\Virtual Machines\\Ubuntu-20.04-Base\\Ubuntu-20.04-Base.vmx"
}

variable "deploy_path" {
  description = "Directory where the new lab VMs will be stored"
  type        = string
  default     = "C:\\Virtual Machines\\VulnLab"
}

variable "ssh_user" {
  description = "Username for the base Ubuntu VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_password" {
  description = "Password for the base Ubuntu VM"
  type        = string
  default     = "ubuntu"
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
