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
    # Get the first non-localhost IPv4 address
    swarm.advertiseAddress = "$(${pkgs.iproute2}/bin/ip -4 addr show scope global | ${pkgs.gnugrep}/bin/grep -oP 'inet \\K[0-9.]+' | head -1)";
  };
}
