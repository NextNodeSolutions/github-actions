{
  # Domain Configuration
  domain = "nextnode.fr";
  adminSubdomain = "admin";
  adminDomain = "admin.nextnode.fr";

  # Email for Let's Encrypt certificates
  acmeEmail = "contact@nextnode.fr";

  # Dokploy Configuration
  dokploy = {
    image = "dokploy/dokploy:v0.25.11";
    internalPort = 3000;
    bindAddress = "127.0.0.1";
  };

  # Traefik Configuration
  traefik = {
    image = "traefik:v3.6.1";
    httpPort = 80;
    httpsPort = 443;
    logLevel = "INFO";
    acmeStorage = "/var/lib/traefik/acme.json";
  };

  # Network Configuration
  firewall = {
    allowedPorts = [ 80 443 ];
    sshEnabled = true;
  };

  # System Configuration
  timezone = "Europe/Paris";
  stateVersion = "24.11";
  hostname = "dokploy-server";

  # Maintenance
  docker = {
    pruneSchedule = "weekly";
    pruneFlags = [ "--all" "--volumes" ];
  };

  nix = {
    gcSchedule = "weekly";
    gcRetention = "30d";
  };
}
