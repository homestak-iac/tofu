# Generic environment variables
# All values resolved by iac-driver's ConfigResolver

variable "node" {
  description = "Target PVE node name"
  type        = string
}

variable "api_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "api_token" {
  description = "Proxmox API token"
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "SSH user for provider connection to PVE host"
  type        = string
  default     = "root"
}

variable "automation_user" {
  description = "User created in VMs via cloud-init (with sudo)"
  type        = string
  default     = "homestak"
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key for provider connection"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_host" {
  description = "SSH host for file uploads (defaults to localhost)"
  type        = string
  default     = "127.0.0.1"
}

variable "datastore" {
  description = "Default datastore for VMs"
  type        = string
  default     = "local-zfs"
}

variable "root_password" {
  description = "Root password hash for cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "SSH public keys for cloud-init"
  type        = list(string)
  sensitive   = true
}

variable "vms" {
  description = "List of VMs to create (resolved by iac-driver)"
  type = list(object({
    name       = string
    vmid       = optional(number)
    image      = string
    cores      = number
    memory     = number
    disk       = number
    bridge     = optional(string, "vmbr0")
    ip         = optional(string, "dhcp")
    gateway    = optional(string)
    packages   = optional(list(string), [])
    auth_token = optional(string, "")
  }))

  validation {
    condition     = alltrue([for vm in var.vms : vm.cores > 0 && vm.cores <= 128])
    error_message = "VM cores must be between 1 and 128."
  }

  validation {
    condition     = alltrue([for vm in var.vms : vm.memory >= 512])
    error_message = "VM memory must be at least 512 MB."
  }

  validation {
    condition     = alltrue([for vm in var.vms : vm.disk >= 1])
    error_message = "VM disk must be at least 1 GB."
  }

  validation {
    condition     = alltrue([for vm in var.vms : can(regex("^[a-z][a-z0-9-]*$", vm.name))])
    error_message = "VM names must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

# DNS servers for cloud-init (v0.51+, #229)
variable "dns_servers" {
  description = "List of DNS servers for cloud-init"
  type        = list(string)
  default     = []
}

# Server URL for provisioning token flow (#231, env var: HOMESTAK_SERVER)
variable "spec_server" {
  description = "Server URL for provisioning token and bootstrap (becomes HOMESTAK_SERVER)"
  type        = string
  default     = ""
}

# Image name to Proxmox file ID mapping
variable "images" {
  description = "Map of image names to Proxmox file IDs"
  type        = map(string)
  default = {
    "debian-12" = "local:iso/debian-12.img"
    "debian-13" = "local:iso/debian-13.img"
    "pve-9"     = "local:iso/pve-9.img"
  }
}
