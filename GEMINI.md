# GEMINI.md

Optimized instructions for Gemini AI working with this repository.

## Repository Summary

**Purpose**: Centralized GitHub Actions repository for NextNode CI/CD automation.

**Key Constraint**: pnpm only. No npm/yarn support.

**Primary Workflows**:
- `quality-checks.yml` - Lint, typecheck, test, build
- `dokploy-deploy.yml` - Deploy to self-hosted Dokploy PaaS
- `release.yml` - NPM package publishing with changesets

## Key Files

| File | Purpose |
|------|---------|
| `config/dokploy-defaults.toml` | Default deployment configuration |
| `.github/workflows/dokploy-deploy.yml` | Main deployment workflow |
| `actions/deploy/dokploy-sync/action.yml` | Core deployment logic |
| `actions/build/docker-build-push/action.yml` | Docker image building |
| `actions/infrastructure/cloudflare-dns-upsert/action.yml` | DNS automation |

## Architecture Summary

```
GitHub Actions → Docker Build → Private Registry → Dokploy → Worker Nodes
                     ↓
              Tailscale VPN (all communication)
                     ↓
              Hetzner Cloud Cluster
              ├── admin-dokploy (Traefik, Registry, Dokploy UI)
              ├── dev-worker (PR/dev deployments)
              └── prod-worker (production apps)
```

## Infrastructure Context

This repo is the **CI/CD layer**. The **infrastructure layer** is in a separate repo:
- Terraform for VPS provisioning
- Packer/NixOS for server configuration
- Dokploy for container orchestration

## Action Domains

| Domain | Path | Purpose |
|--------|------|---------|
| build | `actions/build/` | Install deps, build, Docker |
| quality | `actions/quality/` | Lint, typecheck, security |
| deploy | `actions/deploy/` | Dokploy sync, VPS provision, routing |
| infrastructure | `actions/infrastructure/` | Tailscale, Cloudflare DNS |
| release | `actions/release/` | Changesets, NPM publish |
| ssl | `actions/ssl/` | Cloudflare SSL setup |
| monitoring | `actions/monitoring/` | Health checks |
| utilities | `actions/utilities/` | Helpers, logging |

**Global actions** (root level): `node-setup-complete`, `test`, `health-check`

## Common Tasks

### Add New Action

```bash
mkdir actions/{domain}/{action-name}
touch actions/{domain}/{action-name}/action.yml
```

Use `action.yml` (not `action.yaml`). Include `::group::` logging.

### Test Locally

```bash
# Install actionlint
brew install actionlint

# Validate workflows
actionlint
```

### External Project Usage

```yaml
# Full workflow
uses: nextnodesolutions/github-actions/.github/workflows/dokploy-deploy.yml@main

# Individual action
uses: nextnodesolutions/github-actions/actions/deploy/dokploy-sync@main
```

## Important Patterns

### Authentication Flow

1. Tailscale OAuth → API token
2. API token → Connect to VPN
3. VPN → Access registry, Dokploy API
4. Dokploy API → Deploy application

### Deployment Configuration

Projects define `dokploy.toml`:
```toml
[project]
name = "my-app"
domain = "myapp.com"

[environments.production]
server = "prod-worker"
```

Defaults from `config/dokploy-defaults.toml` are merged.

### Unified Swarm Architecture

All worker nodes are part of the same Docker Swarm cluster as admin-dokploy:
1. Services deploy to workers via Swarm placement constraints
2. Traefik routes to services via Swarm overlay network
3. DNS points to admin-dokploy (Traefik ingress)

## Required Secrets

| Secret | Required For |
|--------|--------------|
| `DOKPLOY_ADMIN_EMAIL` | All deployments |
| `DOKPLOY_ADMIN_PASSWORD` | All deployments |
| `TAILSCALE_OAUTH_CLIENT_ID` | All deployments |
| `TAILSCALE_OAUTH_SECRET` | All deployments |
| `CLOUDFLARE_API_TOKEN` | DNS configuration |
| `HETZNER_TOKEN` | Custom VPS only |
| `TF_API_TOKEN` | Custom VPS only |
| `NPM_TOKEN` | NPM publishing |

## Do NOT

- Use npm or yarn (pnpm only)
- Add push/pull_request triggers to internal workflows
- Place new actions at root level (use domains)
- Hardcode secrets in actions
- Use `action.yaml` (use `action.yml`)
