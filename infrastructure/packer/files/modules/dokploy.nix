{ config, pkgs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  services.dokploy = {
    enable = true;
    image = vars.dokploy.image;
    port = "${vars.dokploy.bindAddress}:${toString vars.dokploy.internalPort}:${toString vars.dokploy.internalPort}";
  };
}
