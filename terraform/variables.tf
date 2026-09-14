variable "pve_endpoint" {
  type = string
  description = "URL endpoint for the proxmox api"
}

variable "pve_api_token" {
  type = string
  description = "proxmox api key, rotates each month"
  sensitive = true
}

variable "pve_node_name" {
  type = string
}

variable pve_datastore_id {
  type = string
}

data "local_file" "ssh_public_key" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}
