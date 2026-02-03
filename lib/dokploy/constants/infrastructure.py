"""Infrastructure constants: servers, registry, ports."""

# Servers
TRAEFIK_SERVER = "admin-dokploy"
DEV_SERVER = "dev-worker"
PROD_SERVER = "prod-worker"

# Registry
REGISTRY_HOST = "registry.nextnode.fr"
REGISTRY_PORT = 5000
REGISTRY_INTERNAL_HOST = "admin-dokploy"

# Ports
DEFAULT_APP_PORT = 3000
DEFAULT_SSH_PORT = 22

# SSH
DEFAULT_SSH_USER = "root"
DEFAULT_SSH_KEY_NAME = "nextnode-dokploy-ci"
