terraform {
  required_version = ">= 1.5"

  # Remote state storage in Terraform Cloud
  cloud {
    organization = "nextnode"

    workspaces {
      name = "dokploy-infrastructure"
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}
