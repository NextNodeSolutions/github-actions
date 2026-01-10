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

      certificatesResolvers.letsencrypt.acme = {
        email = vars.acmeEmail;
        storage = vars.traefik.acmeStorage;
        httpChallenge.entryPoint = "web";
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

  # Create Traefik data directory for ACME certificates
  systemd.tmpfiles.rules = [
    "d /var/lib/traefik 0755 root root -"
  ];
}
