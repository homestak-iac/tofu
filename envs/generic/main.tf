# Environment: generic
# Primary execution environment for iac-driver workflows.
#
# Receives pre-resolved configuration via tfvars.json from ConfigResolver.
# No direct site-config access - all values passed as variables.
#
# Usage: tofu apply -var-file=/path/to/tfvars.json

locals {
  # Convert vms list to map keyed by name
  vms_map = { for vm in var.vms : vm.name => vm }

  # Generate cloud-init user-data for each VM
  user_data = { for name, vm in local.vms_map : name => <<-EOF
    #cloud-config
    hostname: ${name}

    users:
      - name: ${var.automation_user}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          ${indent(10, join("\n", formatlist("- \"%s\"", var.ssh_keys)))}
      - name: root
        lock_passwd: false
        hashed_passwd: ${var.root_password}

    package_update: ${length(vm.packages) > 0 ? "true" : "false"}
    packages:
      - qemu-guest-agent
      ${indent(4, join("\n", formatlist("- %s", vm.packages)))}
%{if var.spec_server != "" && vm.auth_token != ""}

    write_files:
      - path: /etc/profile.d/homestak.sh
        permissions: '0644'
        content: |
          # Homestak provisioning environment variables (#231)
          export HOMESTAK_SERVER=${var.spec_server}
          export HOMESTAK_TOKEN=${vm.auth_token}
%{endif}

    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
%{if var.spec_server != "" && vm.auth_token != ""}
      - |
        # Bootstrap from server + config on first boot (#231)
        if [ ! -f ~homestak/config/.state/config-complete.json ]; then
          . /etc/profile.d/homestak.sh
          curl -fsSk "$HOMESTAK_SERVER/bootstrap.git/install" | \
            HOMESTAK_SOURCE="$HOMESTAK_SERVER" HOMESTAK_REF=_working \
            HOMESTAK_INSECURE=1 SKIP_SITE_CONFIG=1 HOMESTAK_APPLY=config bash
        fi
%{endif}
  EOF
  }
}

module "vm" {
  source   = "../../proxmox-vm"
  for_each = local.vms_map

  proxmox_node_name = var.node
  vm_id             = each.value.vmid
  vm_name           = each.key
  vm_datastore_id   = var.datastore

  cloud_image_id = var.images[each.value.image]

  vm_cpu_cores = each.value.cores
  vm_memory    = each.value.memory
  vm_disk_size = each.value.disk

  network_devices = [{ bridge = each.value.bridge }]

  cloud_init_user_data = local.user_data[each.key]

  vm_ipv4_address = each.value.ip
  vm_ipv4_gateway = each.value.ip == "dhcp" ? null : each.value.gateway
  vm_dns_servers  = length(var.dns_servers) > 0 ? var.dns_servers : null
}
