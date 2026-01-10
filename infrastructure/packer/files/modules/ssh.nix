{ config, pkgs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Configure root user with authorized SSH keys from variables
  users.users.root.openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
}
