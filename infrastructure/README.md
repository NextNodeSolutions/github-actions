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
│              ┌───────────────────┼───────────────────┐                     │
│              │                   │                   │                      │
│              ▼                   ▼                   ▼                      │
│    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│    │  ADMIN SERVER   │  │  DEV WORKER     │  │  PROD WORKER    │          │
│    │  admin-dokploy  │  │  dev-worker     │  │  prod-worker    │          │
│    │  (cx23)         │  │  (cx23)         │  │  (cx33)         │          │
│    │                 │  │                 │  │                 │          │
│    │  DOKPLOY UI     │  │  Docker         │  │  Docker         │          │
│    │  Docker         │  │  Traefik        │  │  Traefik        │          │
│    │  Traefik        │  │  (Worker)       │  │  (Worker)       │          │
│    └────────┬────────┘  └─────────────────┘  └─────────────────┘          │
│             │                   ▲                   ▲                      │
│             │      SSH          │      SSH          │                      │
│             └───────────────────┴───────────────────┘                      │
│                                                                             │
│  Workflow: .github/workflows/infra-provision.yml                           │
│  Config: infrastructure/terraform/                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PHASE 3: DNS (Cloudflare)                           │
│                                                                             │
│          admin.nextnode.fr ───────────► admin-dokploy IP                   │
│                                                                             │
│  Single Dokploy instance manages all workers via SSH                        │
│  Configured automatically after terraform apply                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Server Architecture

| Server | Type | Cost | Purpose |
|--------|------|------|---------|
| `admin-dokploy` | cx23 | ~€3.49/mo | Dokploy UI, manages all workers |
| `dev-worker` | cx23 | ~€3.49/mo | Dev apps, PR previews, staging |
| `prod-worker` | cx33 | ~€5.49/mo | Production apps |

**Total: ~€12.50/month**

## Accessing Dokploy

| URL | Purpose |
|-----|---------|
| `https://admin.nextnode.fr:3000` | Dokploy Dashboard (manages all servers) |

### First-Time Setup

1. Access `https://admin.nextnode.fr:3000`
2. Create an admin account
3. Connect your GitHub account for repository access
4. Add worker servers (see below)

### Adding Worker Servers

After first login to Dokploy:

1. Go to **Settings → Servers**
2. Click **Add Server**
3. Add dev worker:
   - Name: `dev-worker`
   - IP: (from workflow output)
   - Configure SSH key
4. Add prod worker:
   - Name: `prod-worker`
   - IP: (from workflow output)
   - Configure SSH key

```
┌─────────────────────────────────────────────────────────────┐
│              DOKPLOY DASHBOARD (admin.nextnode.fr)          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Servers                                            │   │
│  │  ├── admin-dokploy (local)  ← Don't deploy here    │   │
│  │  ├── dev-worker (remote)    ← Dev/staging apps     │   │
│  │  └── prod-worker (remote)   ← Production apps      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Deploy to dev:  *.dev.nextnode.fr                         │
│  Deploy to prod: *.nextnode.fr                             │
└─────────────────────────────────────────────────────────────┘
```

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
│  Server: prod-worker (or dev-worker)                           │
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

## Terraform Cloud Setup

State is stored in Terraform Cloud for persistence across workflow runs.

### Initial Setup

1. **Create Terraform Cloud account**: https://app.terraform.io
2. **Create organization**: `nextnode`
3. **Create workspace**: `dokploy-infrastructure` (CLI-Driven Workflow)
4. **Set execution mode to Local**:
   - Workspace → Settings → General → Execution Mode → Local
5. **Create API token**:
   - User Settings → Tokens → Create an API token
6. **Add secret to GitHub**:
   - Repository → Settings → Secrets → `TF_API_TOKEN`

### Why Terraform Cloud?

Without remote state, each GitHub Actions run starts fresh and doesn't know about existing resources. This caused the `destroy` action to fail because it had no state to destroy.

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
      "admin": "cx23",
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
    "admin_subdomain": "admin"
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

### SSH Access

```bash
# Connect to admin server
ssh root@<admin-ip>

# Connect to dev worker
ssh root@<dev-ip>

# Connect to prod worker
ssh root@<prod-ip>
```

### Check Server IPs

After `apply`, check the workflow logs for:
```
admin_ip = "x.x.x.x"
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

### Why 3 Servers (Admin + Dev + Prod)?

- **Admin isolation**: Dokploy UI separated from workloads
- **Dev/Prod separation**: Dev apps can't affect production
- **Clean management**: Admin server only manages, doesn't run apps
- **Easy scaling**: Add more workers as needed

### Why Terraform Cloud?

- **Persistent state**: State survives across GitHub Actions runs
- **Destroy works**: Terraform knows what resources exist
- **Team collaboration**: Multiple people can see state
- **Free tier**: Sufficient for small teams

## Troubleshooting

### Server Not Accessible

1. Check Hetzner console for server status
2. Verify firewall rules (ports 22, 80, 443, 3000 should be open)
3. Check DNS propagation: `dig admin.nextnode.fr`
4. Try direct IP access: `https://<admin-ip>:3000`

### Dokploy Not Starting

SSH into server and check:
```bash
systemctl status dokploy-stack
docker ps
journalctl -u dokploy-stack -n 50
```

### Cannot SSH into Server

1. Ensure your SSH key is added to Hetzner project
2. Check firewall allows port 22
3. Use Hetzner web console as fallback

### Terraform Destroy Not Working

1. Ensure Terraform Cloud is configured
2. Check TF_API_TOKEN secret is set
3. Verify workspace execution mode is "Local"

### Rebuild from Scratch

1. Destroy existing servers: `gh workflow run "Provision Infrastructure" -f action=destroy`
2. Rebuild image: `gh workflow run "Build Infrastructure Image"`
3. Wait for completion
4. Apply: `gh workflow run "Provision Infrastructure" -f action=apply`
