# Tofu Architecture

How the OpenTofu layer fits into the homestak platform and why it is designed
the way it is.

## The "Generic" Environment

The `envs/generic/` directory is the sole tofu environment. There is no `dev`
vs `prod` environment split. Instead, a single generic environment handles all
manifests by receiving fully-resolved configuration from iac-driver's
ConfigResolver.

**Why:** Config resolution logic (merging presets, specs, postures, secrets)
lives in Python where it is testable and expressive. Tofu is a "dumb executor"
that loops over `var.vms` and provisions what it is told. This means:

- All config knowledge stays in one place (iac-driver, not duplicated in HCL)
- A single `for_each = { for vm in var.vms : vm.name => vm }` handles any
  manifest topology
- No HCL conditionals for environment-specific behavior
- Template/preset inheritance is handled by ConfigResolver, not by tofu
  variable defaults

## The Provider Constraint

The `bpg/proxmox` provider (see `providers.tf` for version) requires SSH access to the PVE
host for one specific operation: uploading cloud-init snippets. The Proxmox VE
API has no endpoint for snippet upload, so the provider SSHes to the host and
writes files directly.

This is configured in `providers.tf`:

```hcl
provider "proxmox" {
  endpoint  = var.api_endpoint
  api_token = var.api_token
  ssh {
    agent       = false
    private_key = file(pathexpand(var.ssh_private_key_file))
    username    = var.vm_user
    node {
      name    = var.node
      address = var.ssh_host
    }
  }
}
```

### Why vm_user for Provider SSH (Not Root)

The provider SSH connection uses `var.vm_user` (default: `homestak`) instead
of root. This was a deliberate change in iac-driver#133 because Proxmox VE
manages `/root/.ssh/authorized_keys` and may overwrite manual additions during
PVE updates or cluster operations. The `homestak` user's `authorized_keys` is
not managed by PVE, so the RSA key placed there by bootstrap persists reliably.

### RSA Key Requirement

The provider's Go SSH library cannot parse OpenSSH-format ed25519 keys. Only
RSA keys work. The key must exist at `~/.ssh/id_rsa` on the host running tofu,
and the corresponding public key must be in the target host's `authorized_keys`.

## Cloud-Init Template Design

The cloud-init user-data template in `envs/generic/main.tf` generates per-VM
configuration at plan time. Key design elements:

**User creation:** Each VM gets a `vm_user` (default: `homestak`) with
passwordless sudo and SSH keys from `var.ssh_keys`. Root gets a hashed password
for emergency console access.

**Package installation:** `qemu-guest-agent` is always installed (required for
IP detection). Additional packages come from the VM's preset/spec via
`vm.packages`.

**Conditional HOMESTAK_SERVER injection:** When both `var.server_url` and
`vm.auth_token` are non-empty, cloud-init writes `HOMESTAK_SERVER` and
`HOMESTAK_TOKEN` to `/etc/profile.d/homestak.sh`. This enables pull-mode config
where VMs self-configure on first boot. When either value is empty, the VM boots
clean without homestak integration.

**boot_scenario dispatch:** The `runcmd` section curls the bootstrap installer
from `HOMESTAK_SERVER` and passes `HOMESTAK_BOOT_SCENARIO` to control what
happens after bootstrap. This allows different VM types (leaf VMs, PVE nodes)
to execute different post-bootstrap workflows.

## The proxmox-vm Module

The `proxmox-vm/` module is a thin wrapper around the `bpg/proxmox` provider's
`proxmox_virtual_environment_vm` and `proxmox_virtual_environment_file`
resources. It provisions a single VM with:

- CPU (host passthrough type), memory, and disk on `local-zfs`
- Dynamic network devices (bridge, optional MAC address, optional VLAN)
- Cloud-init user-data uploaded as a snippet
- Optional cloud-init network-data (for advanced networking)
- QEMU guest agent enabled
- Serial device configured (prevents Debian 12 first-boot kernel panic)
- Startup ordering with configurable boot delay

The module does not contain any config resolution logic. All values arrive
as variables from `envs/generic/`, which receives them from iac-driver's
tfvars.json.

When `cloud_init_network_data` is provided, the module uses it directly and
skips the Proxmox `ip_config`/`dns` blocks. Otherwise, it uses Proxmox-native
IP configuration with `var.vm_ipv4_address` and `var.vm_dns_servers`.

## State Isolation

Each manifest + node combination gets its own tofu state file. iac-driver
manages this via the `-state` flag:

```
~/.state/tofu/{env}-{node}/
├── data/                 # TF_DATA_DIR (modules, providers)
│   ├── modules/
│   └── providers/
└── terraform.tfstate     # state file (at parent level, not inside data/)
```

The state file is stored at the parent level rather than inside `TF_DATA_DIR`
to work around an OpenTofu bug (opentofu/opentofu#3643) where state files
inside `TF_DATA_DIR` trigger a false "state version 4 not supported" error.

This isolation means:
- Multiple manifests can target the same PVE host without state conflicts
- `manifest destroy` only affects VMs from its own manifest
- State files are per-host, never shared between machines
- No remote state backend needed (each host manages its own local state)

## Data Flow Summary

```
config/manifests/     iac-driver            tofu/envs/generic/
  + presets/         ConfigResolver              main.tf
  + specs/     -->   resolve_inline_vm()  -->   module "vm" {
  + secrets/         outputs tfvars.json        for_each = var.vms
  + nodes/                                      ...
  + hosts/                                    }
```

1. Operator runs `./run.sh manifest apply -M <manifest> -H <host>`
2. iac-driver loads the manifest, resolves all FKs (preset, spec, host, node)
3. ConfigResolver produces a flat `tfvars.json` with the `vms` list
4. iac-driver runs `tofu init` then `tofu apply -var-file=tfvars.json`
5. Tofu provisions VMs via the PVE API, uploads cloud-init via SSH
6. VMs boot with cloud-init, optionally self-configure via pull mode
