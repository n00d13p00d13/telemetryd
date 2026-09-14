resource "proxmox_virtual_environment_vm" "debian_template" {
  name = "debian-template"
  node_name = var.pve_node_name

  template = true
  started = false

  description = "Managed by Terraform. SSH and QEMU Guest Agent configured"

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type = "host"
  }

  memory { 
    dedicated = 2048
    floating = 1024
  }

  initialization {
    datastore_id = var.pve_datastore_id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "auto"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.debian_user_cloud_config.id
  }

  disk {
    datastore_id = var.pve_datastore_id
    import_from = proxmox_download_file.debian_cloud_image.id
    interface = "virtio0"
    iothread = true
    discard = "on"
    size = 20
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_download_file" "debian_cloud_image" {
  content_type = "import"
  datastore_id = var.pve_datastore_id
  node_name = var.pve_node_name
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  file_name = "debian-13-generic-amd64.qcow2"
}

resource "proxmox_virtual_environment_file" "debian_user_cloud_config" {
  content_type = "snippets"
  datastore_id = var.pve_datastore_id
  node_name = var.pve_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: deb13
    timezone: Africa/Cairo
    users:
      - default
      - name: debtest
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "user-debian-cloud-config.yaml"
  }
}

