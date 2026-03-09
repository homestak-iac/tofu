# tofu

OpenTofu modules for Proxmox VM provisioning with cloud-init.

## Overview

This repo provides two things:

1. **Reusable modules** - `proxmox-vm`, `proxmox-file`, `proxmox-sdn` can be used standalone by anyone doing Proxmox + OpenTofu work

2. **homestak integration** - `envs/generic` is the execution layer for [iac-driver](https://github.com/homestak-dev/iac-driver) workflows

Part of the [homestak-dev](https://github.com/homestak-dev) organization.

## Quick Start

### Option A: Full homestak (recommended)

Use iac-driver for manifest-driven VM provisioning:

```bash
# Install homestak
curl -fsSL https://raw.githubusercontent.com/homestak/bootstrap/master/install | sudo bash

# Switch to homestak user, deploy and test a VM
sudo -iu homestak
cd ~/lib/iac-driver
./run.sh manifest test -M n1-push -H <nodename>
```

### Option B: Module reuse (advanced)

Use modules directly in your own OpenTofu configuration:

```hcl
module "vm" {
  source = "github.com/homestak-dev/tofu//proxmox-vm"

  proxmox_node_name    = "pve"
  vm_name              = "my-vm"
  cloud_image_id       = "local:iso/debian-12.img"
  cloud_init_user_data = file("cloud-init.yaml")

  vm_cpu_cores = 2
  vm_memory    = 4096
  vm_disk_size = 20
}
```

### Option C: Direct generic env (debugging only)

Requires manually crafted tfvars.json matching iac-driver schema:

```bash
cd envs/generic
tofu init
tofu plan -var-file=/path/to/tfvars.json
tofu apply -var-file=/path/to/tfvars.json
```

## Project Structure

```
tofu/
├── proxmox-vm/       # Reusable: VM provisioning with cloud-init
├── proxmox-file/     # Reusable: cloud image management
├── proxmox-sdn/      # Reusable: VXLAN SDN networking
└── envs/
    └── generic/      # homestak: receives config from iac-driver
```

## Modules

| Module | Purpose |
|--------|---------|
| `proxmox-vm` | Single VM with CPU, memory, disk, network, cloud-init |
| `proxmox-file` | Cloud image management (local or URL source) |
| `proxmox-sdn` | VXLAN zone, vnet, and subnet configuration |

## Prerequisites

- OpenTofu CLI
- Proxmox VE with API access
- SSH key at `~/.ssh/id_rsa`

For full homestak integration:
- [bootstrap](https://github.com/homestak-dev/bootstrap) installed
- [site-config](https://github.com/homestak-dev/site-config) set up and decrypted

## Documentation

See [CLAUDE.md](CLAUDE.md) for detailed architecture, configuration flow, and known issues.

## Third-Party Acknowledgments

| Dependency | Purpose | License |
|------------|---------|---------|
| [bpg/proxmox](https://github.com/bpg/terraform-provider-proxmox) | OpenTofu provider for Proxmox API | MPL-2.0 |

## Related Repos

| Repo | Purpose |
|------|---------|
| [bootstrap](https://github.com/homestak-dev/bootstrap) | Entry point - curl\|bash setup |
| [site-config](https://github.com/homestak-dev/site-config) | Site-specific secrets and configuration |
| [ansible](https://github.com/homestak-dev/ansible) | Proxmox host configuration |
| [iac-driver](https://github.com/homestak-dev/iac-driver) | Orchestration engine |
| [packer](https://github.com/homestak-dev/packer) | Custom Debian cloud images |

## License

Apache 2.0 - see [LICENSE](LICENSE)
