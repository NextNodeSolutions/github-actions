{ config, pkgs, ... }:

{
  system.stateVersion = "24.11";

  networking.hostName = "dokploy-server";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 3000 ];
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

  services.openssh.enable = false;

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    vim
    curl
    htop
    jq
  ];
}
