{ config, pkgs, lib, ... }:

let
  vars = import ./modules/variables.nix;
in
{
  imports = [
    ./modules/docker.nix
    ./modules/dokploy.nix
    ./modules/traefik.nix
    ./modules/ssh.nix
  ];

  system.stateVersion = vars.stateVersion;

  networking = {
    hostName = vars.hostname;
    firewall = {
      enable = true;
      allowedTCPPorts = vars.firewall.allowedPorts
        ++ (if vars.firewall.sshEnabled then [ 22 ] else []);
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = vars.nix.gcSchedule;
      options = "--delete-older-than ${vars.nix.gcRetention}";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  time.timeZone = vars.timezone;

  environment.systemPackages = with pkgs; [
    vim
    curl
    htop
    jq
  ];
}
