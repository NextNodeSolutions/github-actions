provider "hcloud" {
  token = var.hetzner_token
}

data "hcloud_image" "nixos_dokploy" {
  with_selector = "type=nixos-dokploy"
  most_recent   = true
}

# Admin server - runs Dokploy UI, manages other servers
module "admin_vps" {
  source = "./modules/hetzner-vps"

  name        = "admin-dokploy"
  server_type = var.admin_server_type
  location    = var.location
  image_id    = data.hcloud_image.nixos_dokploy.id
  ssh_keys    = var.ssh_keys

  labels = {
    environment = "management"
    managed_by  = "terraform"
    service     = "dokploy"
    role        = "admin"
  }
}

# Dev server - worker node for development/PR deployments
module "dev_vps" {
  source = "./modules/hetzner-vps"

  name        = "dev-worker"
  server_type = var.dev_server_type
  location    = var.location
  image_id    = data.hcloud_image.nixos_dokploy.id
  ssh_keys    = var.ssh_keys

  labels = {
    environment = "development"
    managed_by  = "terraform"
    service     = "dokploy"
    role        = "worker"
  }
}

# Prod server - worker node for production deployments
module "prod_vps" {
  source = "./modules/hetzner-vps"

  name        = "prod-worker"
  server_type = var.prod_server_type
  location    = var.location
  image_id    = data.hcloud_image.nixos_dokploy.id
  ssh_keys    = var.ssh_keys

  labels = {
    environment = "production"
    managed_by  = "terraform"
    service     = "dokploy"
    role        = "worker"
  }
}
