# using proxmox_virtual_environment_vm instead of proxmox_cloned_vm
# for simple configuration purposes
resource "proxmox_virtual_environment_vm" "debtest_clone" {
  count = 3
  name = "debtest-clone-${count.index + 1}"
  node_name = var.pve_node_name

  clone {
    vm_id = proxmox_virtual_environment_vm.debian_template.vm_id
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
    user_data_file_id = proxmox_virtual_environment_file.debian_user_cloud_config.id

    dns {
      servers = ["192.168.1.111"]
    }
    ip_config {
      ipv4 {
        address = "192.168.1.${121 + count.index}/23"
        gateway = "192.168.1.1"
      }
      ipv6 {
        address = "auto"
      }
    }
  }

}

resource "local_file" "ansible_inventory" {
  filename = pathexpand("../ansible/inventory.ini")
  content = 
}

output "vm_ids" {
  value = proxmox_virtual_environment_vm.debtest_clone[*].vm_id
}
