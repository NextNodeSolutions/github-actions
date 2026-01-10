{ config, pkgs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = vars.docker.pruneSchedule;
      flags = vars.docker.pruneFlags;
    };
    daemon.settings = {
      live-restore = false;
    };
  };
}
