{ config, pkgs, ... }:

{
  system.stateVersion = "24.11";

  networking.hostName = "dokploy-server";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 3000 ];
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--volumes" ];
    };
    daemon.settings = {
      live-restore = false;
    };
  };

  services.dokploy.enable = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  # Enable SSH for remote access and Dokploy multi-server management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    vim
    curl
    htop
    jq
  ];
}
