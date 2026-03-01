terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.94.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.api_endpoint
  api_token = var.api_token
  insecure  = true
  ssh {
    agent       = false
    private_key = file(pathexpand(var.ssh_private_key_file))
    username    = var.ssh_user
    node {
      name    = var.node
      address = var.ssh_host
    }
  }
  random_vm_ids = true
  tmp_dir       = "/var/tmp"
}
