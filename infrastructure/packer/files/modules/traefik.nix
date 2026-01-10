{ config, pkgs, lib, ... }:

let
  vars = import ./variables.nix;
in
{
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":${toString vars.traefik.httpPort}";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":${toString vars.traefik.httpsPort}";
        };
      };

      # Use TLS-ALPN challenge (works over port 443, doesn't conflict with HTTP redirect)
      certificatesResolvers.letsencrypt.acme = {
        email = vars.acmeEmail;
        storage = vars.traefik.acmeStorage;
        tlsChallenge = {};  # TLS-ALPN-01 challenge
      };

      log.level = vars.traefik.logLevel;
    };

    dynamicConfigOptions = {
      http = {
        routers.dokploy = {
          rule = "Host(`${vars.adminDomain}`)";
          service = "dokploy";
          entryPoints = [ "websecure" ];
          tls.certResolver = "letsencrypt";
        };
        services.dokploy.loadBalancer.servers = [
          { url = "http://${vars.dokploy.bindAddress}:${toString vars.dokploy.internalPort}"; }
        ];
      };
    };
  };

  # Create Traefik data directory with correct ownership (traefik user)
  systemd.tmpfiles.rules = [
    "d /var/lib/traefik 0700 traefik traefik -"
    "f /var/lib/traefik/acme.json 0600 traefik traefik -"
  ];
}
