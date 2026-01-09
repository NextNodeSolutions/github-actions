packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = ">= 1.4.0"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "location" {
  type    = string
  default = "fsn1"
}

source "hcloud" "nixos" {
  token        = var.hcloud_token
  image        = "ubuntu-24.04"
  location     = var.location
  server_type  = "cx22"
  ssh_username = "root"
  snapshot_name = "nixos-dokploy-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  snapshot_labels = {
    type       = "nixos-dokploy"
    managed_by = "packer"
  }
}

build {
  sources = ["source.hcloud.nixos"]

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y curl xz-utils",
      "curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes",
      "source /etc/profile.d/nix.sh",
      "nix-channel --add https://nixos.org/channels/nixos-24.11 nixpkgs",
      "nix-channel --update"
    ]
  }

  provisioner "file" {
    source      = "files/"
    destination = "/etc/nixos/"
  }

  provisioner "shell" {
    inline = [
      "source /etc/profile.d/nix.sh",
      "cd /etc/nixos",
      "nix flake update",
      "nixos-generate-config --root /",
      "nixos-rebuild switch --flake .#dokploy-server"
    ]
  }

  provisioner "shell" {
    inline = [
      "nix-collect-garbage -d",
      "rm -rf /root/.cache",
      "sync"
    ]
  }
}
