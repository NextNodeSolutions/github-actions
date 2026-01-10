{ config, pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Systemd service to fetch SSH keys from Hetzner metadata service on boot
  # This runs before SSH starts and ensures authorized_keys is up to date
  systemd.services.hetzner-ssh-keys = {
    description = "Fetch SSH public keys from Hetzner Cloud metadata";
    wantedBy = [ "multi-user.target" ];
    before = [ "sshd.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -eu
      mkdir -p /root/.ssh
      chmod 700 /root/.ssh

      # Fetch SSH keys from Hetzner metadata service
      # The metadata service is available at 169.254.169.254
      ${pkgs.curl}/bin/curl -sf \
        --connect-timeout 5 \
        --max-time 10 \
        http://169.254.169.254/hetzner/v1/metadata/public-keys \
        > /root/.ssh/authorized_keys.new 2>/dev/null || true

      # Only update if we got valid keys
      if [ -s /root/.ssh/authorized_keys.new ]; then
        mv /root/.ssh/authorized_keys.new /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
        echo "SSH keys updated from Hetzner metadata"
      else
        rm -f /root/.ssh/authorized_keys.new
        echo "No SSH keys from metadata service, keeping existing"
      fi
    '';
  };
}
