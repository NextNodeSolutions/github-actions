# Traefik Routing Implementation

Detailed documentation for Traefik routing in the app-deploy workflow.

## Overview

The `app-deploy.yml` workflow determines where to deploy Traefik routing configuration based on the deployment type (shared worker vs custom VPS).

## Traefik Target Logic

Located in `app-deploy.yml` at the "Determine Traefik Target" step (lines 541-566):

```yaml
# Pseudocode
IF vps-enabled == "true" AND server != traefik-server:
    target-ip = server-tailscale-ip     # VPS's own Traefik
    same-server = true                   # Backend is localhost
ELSE:
    target-ip = traefik-tailscale-ip    # Centralized Traefik (admin-dokploy)
    same-server = (server == traefik-server)
```

### Why This Matters

- Custom VPS runs its own Traefik instance
- Config MUST be deployed to the correct Traefik server
- Wrong target = 404 errors (DNS points to VPS, but Traefik has no config)

### Related Bug Fix

Commit `841fe8d fix(traefik): deploy routing config to VPS's own Traefik for custom VPS deployments`

**Problem**: For custom VPS deployments, Traefik config was incorrectly deployed to admin-dokploy instead of the VPS's own Traefik.

**Symptoms**:
- DNS correctly pointed to VPS public IP
- VPS had Traefik running
- VPS Traefik had no config for the domain
- Result: 404 errors

**Fix**: Added target determination logic that checks `vps-enabled` and routes config to the correct Traefik instance.

## compose-traefik-routing Action

Located at `actions/deploy/compose-traefik-routing/action.yml`

Deploys Traefik routing config via Tailscale SSH.

### Inputs

| Input | Description |
|-------|-------------|
| `compose-name` | Stack name for router/service names |
| `domain` | Domain to route |
| `service-port` | Container port |
| `server-tailscale-ip` | VPS Tailscale IP (for backend URL) |
| `traefik-tailscale-ip` | WHERE to deploy config |
| `same-server` | `true` = localhost backend, `false` = Tailscale backend |
| `use-https` | Whether to configure HTTPS (false for previews) |

### Output Location

Config is written to `/etc/traefik/dynamic/{name}.yml` on the target server.

Traefik auto-reloads via file provider watch.

### Backend URL Logic

```bash
if same-server == "true":
    backend = "http://127.0.0.1:${port}"
else:
    backend = "http://${server-tailscale-ip}:${port}"
```

## server-resolve Action

Located at `actions/app/server-resolve/action.yml`

Resolves server IPs and determines DNS targets.

### Outputs

| Output | Description |
|--------|-------------|
| `server-id` | Dokploy server ID |
| `server-public-ip` | Hetzner public IP |
| `server-tailscale-ip` | VPS Tailscale IP |
| `traefik-public-ip` | Traefik server Hetzner IP |
| `traefik-tailscale-ip` | Traefik server Tailscale IP (for SSH access) |
| `dns-ip` | IP for DNS record (based on exposure type) |

### Exposure Types

| Type | DNS Points To | Use Case |
|------|---------------|----------|
| `external` | Hetzner public IP | Public apps (Cloudflare proxied) |
| `internal` | Tailscale IP | VPN-only access |

## Workflow Job Dependencies

```
config
  |
  +-> notify-started (parallel)
  |
  +-> provision (if vps.enabled)
  |
  +-> build (if not compose)
       |
       +-> notify-approval-pending (prod only)
            |
            +-> deploy
                 |
                 +-> notify-result
```

## Debugging Routing Issues

### 1. Verify DNS Target

```bash
dig +short projects.nextnode.fr
# Should return the VPS public IP for distributed Traefik
```

### 2. Check Traefik Config Exists

```bash
tailscale ssh root@plane-worker cat /etc/traefik/dynamic/compose-plane-*.yml
```

### 3. Check Traefik is Running

```bash
tailscale ssh root@plane-worker systemctl status traefik
```

### 4. Check Container is Up

```bash
tailscale ssh root@plane-worker docker ps | grep plane
```

### 5. Check Traefik Logs

```bash
tailscale ssh root@plane-worker journalctl -u traefik -f
```

## Key Secrets Required

| Secret | Purpose |
|--------|---------|
| `TAILSCALE_OAUTH_*` | VPN access, Tailscale SSH |
| `DOKPLOY_API_TOKEN` | Dokploy API authentication |
| `CLOUDFLARE_API_TOKEN` | DNS record management |
| `HETZNER_TOKEN` | VPS provisioning, IP lookup |
| `TF_API_TOKEN` | Terraform Cloud state |
