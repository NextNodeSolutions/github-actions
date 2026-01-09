resource "hcloud_server" "this" {
  name        = var.name
  server_type = var.server_type
  location    = var.location
  image       = var.image_id
  labels      = var.labels
  ssh_keys    = var.ssh_keys
  user_data   = var.user_data

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    ignore_changes = [
      ssh_keys,
      user_data,
    ]
  }
}
