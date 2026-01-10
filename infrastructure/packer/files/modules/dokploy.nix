{ config, pkgs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  services.dokploy = {
    enable = true;
    image = vars.dokploy.image;
    port = "${vars.dokploy.bindAddress}:${toString vars.dokploy.internalPort}:${toString vars.dokploy.internalPort}";

    # Fix: NixOS doesn't have 'hostname -I', use ip command instead
    swarm.advertiseAddress = {
      command = "ip -4 addr show scope global | grep -oP 'inet \\K[0-9.]+' | head -1";
      extraPackages = [ pkgs.iproute2 pkgs.gnugrep ];
    };
  };
}
