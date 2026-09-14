provider "proxmox" {
  endpoint = var.pve_endpoint
  api_token = var.pve_api_token
  insecure = true
}

data "proxmox_virtual_environment_vms" "debtest_template" {
  node_name = var.pve_node_name
  filter {
    name = "name"
    values = ["debtesttemplate"]
  }
}

# using proxmox_virtual_environment_vm instead of proxmox_cloned_vm
# for simple configuration purposes
resource "proxmox_virtual_environment_vm" "debtest_clone" {
  count = 3
  name = "debtest-clone-${count.index + 1}"
  node_name = var.pve_node_name

  clone {
    vm_id = data.proxmox_virtual_environment_vms.debtest_template.vms[0].vm_id
    datastore_id = var.pve_datastore_id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
    floating = 2048
  }

  initialization {
    datastore_id = var.pve_datastore_id
    dns {
      servers = ["192.168.1.111"]
    }
    ip_config {
      ipv4 {
        address = "192.168.1.12${count.index + 1}/23"
        gateway = "192.168.1.1"
      }
      ipv6 {
        address = "auto"
      }
    }
  }

}

output "vm_ids" {
  value = proxmox_virtual_environment_vm.debtest_clone[*].vm_id
}
