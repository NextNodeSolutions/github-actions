provider "hcloud" {
  token = var.hetzner_token
}

data "hcloud_image" "nixos_dokploy" {
  with_selector = "type=nixos-dokploy"
  most_recent   = true
}

module "dev_vps" {
  source = "./modules/hetzner-vps"

  name        = "dev-dokploy"
  server_type = var.dev_server_type
  location    = var.location
  image_id    = data.hcloud_image.nixos_dokploy.id
  ssh_keys    = var.ssh_keys

  labels = {
    environment = "development"
    managed_by  = "terraform"
    service     = "dokploy"
  }
}

module "prod_vps" {
  source = "./modules/hetzner-vps"

  name        = "prod-dokploy"
  server_type = var.prod_server_type
  location    = var.location
  image_id    = data.hcloud_image.nixos_dokploy.id
  ssh_keys    = var.ssh_keys

  labels = {
    environment = "production"
    managed_by  = "terraform"
    service     = "dokploy"
  }
}
