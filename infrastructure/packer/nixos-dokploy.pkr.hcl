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
  type        = string
  description = "Hetzner datacenter location (from infrastructure/config.json via workflow)"
}

source "hcloud" "nixos" {
  token        = var.hcloud_token
  image        = "ubuntu-24.04"
  location     = var.location
  server_type  = "cx23"
  ssh_username = "root"
  snapshot_name = "nixos-dokploy-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  snapshot_labels = {
    type       = "nixos-dokploy"
    managed_by = "packer"
  }
}

build {
  sources = ["source.hcloud.nixos"]

  # Step 1: Prepare Ubuntu and create NixOS config directory
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "apt-get update",
      "apt-get install -y curl git"
    ]
  }

  # Step 2: Create /etc/nixos directory for our configuration
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "mkdir -p /etc/nixos"
    ]
  }

  # Step 3: Upload our NixOS flake configuration
  provisioner "file" {
    source      = "files/"
    destination = "/etc/nixos"
  }

  # Step 4: Run nixos-infect to convert Ubuntu to NixOS with our flake
  # nixos-infect handles: installing Nix, generating hardware-configuration.nix,
  # and running nixos-rebuild switch with our flake
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    environment_vars = [
      "NIX_CHANNEL=nixos-24.11",
      "NIXOS_FLAKE=/etc/nixos#dokploy-server",
      "NO_REBOOT=1"
    ]
    inline = [
      "curl -L https://github.com/elitak/nixos-infect/raw/master/nixos-infect | bash -x"
    ]
  }

  # Step 5: Clean up to minimize snapshot size
  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    inline = [
      "source /etc/profile.d/nix.sh || true",
      "nix-collect-garbage -d || true",
      "rm -rf /root/.cache",
      "rm -rf /tmp/*",
      "sync"
    ]
  }
}
