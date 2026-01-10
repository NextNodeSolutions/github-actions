# Dokploy Infrastructure

Self-hosted PaaS infrastructure on Hetzner Cloud with NixOS and Dokploy.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE 1: BUILD IMAGE (Packer)                       │
│                                                                             │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐                 │
│  │  1. Create  │      │  2. Install │      │  3. Take    │                 │
│  │  TEMPORARY  │ ───► │  NixOS +    │ ───► │  SNAPSHOT   │                 │
│  │  Server     │      │  Dokploy    │      │  of disk    │                 │
│  └─────────────┘      └─────────────┘      └─────────────┘                 │
│         │                                         │                         │
│         │                                         ▼                         │
│         │                               ┌─────────────────┐                │
│         │                               │  SNAPSHOT       │                │
│         ▼                               │  "nixos-dokploy │                │
│  ┌─────────────┐                        │   -YYYYMMDD"    │                │
│  │  4. DELETE  │                        │                 │                │
│  │  temporary  │                        │  (Reusable      │                │
│  │  server     │                        │   golden image) │                │
│  └─────────────┘                        └─────────────────┘                │
│                                                  │                         │
│  Workflow: .github/workflows/infra-image.yml    │                         │
│  Config: infrastructure/packer/                  │                         │
└──────────────────────────────────────────────────┼─────────────────────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PHASE 2: PROVISION (Terraform)                         │
│                                                                             │
│                         ┌─────────────────┐                                 │
│                         │  SNAPSHOT       │                                 │
│                         │  "nixos-dokploy"│                                 │
│                         └────────┬────────┘                                 │
│                                  │                                          │
│                    ┌─────────────┴─────────────┐                           │
│                    │                           │                            │
│                    ▼                           ▼                            │
│          ┌─────────────────┐         ┌─────────────────┐                   │
│          │  DEV SERVER     │         │  PROD SERVER    │                   │
│          │  dev-dokploy    │         │  prod-dokploy   │                   │
│          │  (cx23)         │         │  (cx33)         │                   │
│          │                 │         │                 │                   │
│          │  Dokploy        │         │  Dokploy        │                   │
│          │  Docker         │         │  Docker         │                   │
│          │  Traefik        │         │  Traefik        │                   │
│          └─────────────────┘         └─────────────────┘                   │
│                                                                             │
│  Workflow: .github/workflows/infra-provision.yml                           │
│  Config: infrastructure/terraform/                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE 3: DNS (Cloudflare)                           │
│                                                                             │
│          dev.admin.nextnode.fr ───────► dev-dokploy IP                     │
│          admin.nextnode.fr ───────────► prod-dokploy IP                    │
│                                                                             │
│  Configured automatically after terraform apply                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Accessing Dokploy

| Environment | URL | Purpose |
|-------------|-----|---------|
| Production | `https://admin.nextnode.fr:3000` | Production deployments |
| Development | `https://dev.admin.nextnode.fr:3000` | Testing, PR previews |

### First-Time Setup

1. Access the Dokploy URL
2. Create an admin account
3. Connect your GitHub account for repository access

## Deploying Applications

```
┌─────────────────────────────────────────────────────────────────┐
│                     DOKPLOY DASHBOARD                           │
│                                                                 │
│  [+ New Project] ──► "my-app"                                  │
│       │                                                         │
│       ▼                                                         │
│  [+ New Service] ──► Application                               │
│       │                                                         │
│       ▼                                                         │
│  Source: GitHub                                                 │
│  Repository: NextNodeSolutions/my-app                          │
│  Branch: main                                                   │
│  Build: Dockerfile / Nixpacks                                  │
│       │                                                         │
│       ▼                                                         │
│  Domain: my-app.nextnode.fr                                    │
│       │                                                         │
│       ▼                                                         │
│  [Deploy] ──► Application live!                                │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Options

- **Dockerfile**: Use your own Dockerfile
- **Nixpacks**: Auto-detect and build (Node.js, Python, Go, etc.)
- **Docker Compose**: Multi-container applications

### Auto-Deploy on Push

Dokploy can automatically deploy when you push to GitHub:
1. In your service settings, enable "Auto Deploy"
2. Configure the branch to watch (e.g., `main`)

## Configuration Files

| File | Purpose |
|------|---------|
| `infrastructure/config.json` | Centralized configuration (locations, server types, DNS) |
| `infrastructure/packer/nixos-dokploy.pkr.hcl` | Packer template for NixOS image |
| `infrastructure/packer/files/` | NixOS flake configuration |
| `infrastructure/terraform/` | Terraform configuration for servers |

### config.json Structure

```json
{
  "hetzner": {
    "location": "nbg1",
    "server_types": {
      "dev": "cx23",
      "prod": "cx33",
      "packer_build": "cx23"
    }
  },
  "cloudflare": {
    "api_base_url": "https://api.cloudflare.com/client/v4"
  },
  "dns": {
    "domain": "nextnode.fr",
    "admin_subdomain": "admin",
    "dev_admin_subdomain": "dev.admin"
  }
}
```

## Workflow Triggers

### Build Image (infra-image.yml)

Triggered by:
- Push to `main` changing `infrastructure/packer/**`
- Push to `main` changing `infrastructure/config.json`
- Manual dispatch

### Provision (infra-provision.yml)

Triggered by:
- Successful completion of Build Image workflow
- Manual dispatch with action: `plan`, `apply`, or `destroy`

## Manual Operations

### Rebuild Image

```bash
gh workflow run "Build Infrastructure Image"
```

### Deploy Servers

```bash
# Plan changes
gh workflow run "Provision Infrastructure" -f action=plan

# Apply changes (creates/updates servers)
gh workflow run "Provision Infrastructure" -f action=apply

# Destroy servers
gh workflow run "Provision Infrastructure" -f action=destroy
```

### Check Server IPs

After `apply`, check the workflow logs for:
```
dev_ip = "x.x.x.x"
prod_ip = "x.x.x.x"
```

## Architecture Decisions

### Why NixOS?

- Declarative configuration (reproducible servers)
- Atomic updates with rollback capability
- Single configuration file for entire system

### Why Packer + Snapshot?

- **Fast provisioning**: New servers boot in ~30 seconds
- **Consistency**: Every server uses the same pre-built image
- **Cost-effective**: Temporary build server deleted after snapshot

### Why Separate Dev/Prod?

- **Isolation**: Dev experiments don't affect production
- **Testing**: Test infrastructure changes on dev first
- **Resources**: Different server sizes for different needs

## Troubleshooting

### Server Not Accessible

1. Check Hetzner console for server status
2. Verify firewall rules (ports 80, 443, 3000 should be open)
3. Check DNS propagation: `dig admin.nextnode.fr`

### Dokploy Not Starting

SSH into server and check:
```bash
systemctl status dokploy-stack
docker ps
```

### Rebuild from Scratch

1. Destroy existing servers: `gh workflow run "Provision Infrastructure" -f action=destroy`
2. Rebuild image: `gh workflow run "Build Infrastructure Image"`
3. Wait for completion
4. Apply: `gh workflow run "Provision Infrastructure" -f action=apply`
