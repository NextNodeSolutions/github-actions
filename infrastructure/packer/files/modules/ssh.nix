{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Enable cloud-init to receive SSH keys from Hetzner Cloud
  # This allows Hetzner to inject SSH keys when the server boots
  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings = {
      # Only use Hetzner's metadata source
      datasource_list = [ "Hetzner" ];
      datasource = {
        Hetzner = {};
      };
    };
  };
}
