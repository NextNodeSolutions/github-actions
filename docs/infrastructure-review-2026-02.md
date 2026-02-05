# Infrastructure Review - February 2026

## Executive Summary

This document captures the infrastructure audit findings and simplification roadmap. The current infrastructure provides excellent automation but with unnecessary implementation complexity.

**Key Finding:** The features are valuable, but the implementation is over-engineered for the actual workload.

---

## Current Architecture

### Servers Inventory

| Server | Type | Role | Monthly Cost | Purpose |
|--------|------|------|--------------|---------|
| admin-dokploy | cpx22 | Swarm Manager | ~8 EUR | Dokploy, Traefik, Registry, Sablier |
| dev-worker | cx23 | Swarm Worker | ~5 EUR | Development/preview deployments |
| prod-worker | cpx22 | Swarm Worker | ~8 EUR | Production apps (shared) |
| plane-worker | cpx22 | Standalone | ~8 EUR | Dedicated VPS for Plane |

**Total:** ~31 EUR/month

### Technology Stack

| Layer | Technology | Complexity | Value |
|-------|------------|------------|-------|
| Provisioning | Terraform + Terraform Cloud | Medium | High |
| Image Building | Packer + NixOS | High | Medium |
| PaaS | Dokploy | Medium | Low (see analysis) |
| Orchestration | Docker Swarm | High | Low (see analysis) |
| Proxy | Traefik (dual mode) | High | High |
| Scale-to-Zero | Sablier | Low | Medium |
| VPN | Tailscale | Low | High |
| CI/CD | GitHub Actions (90+ actions) | High | High |

---

## Complexity Analysis

### What Provides Real Value

| Component | Why It's Essential |
|-----------|-------------------|
| **Terraform** | Infrastructure as Code, reproducible provisioning |
| **Tailscale** | Secure inter-server communication, CI/CD access |
| **Traefik** | Reverse proxy, automatic HTTPS, routing |
| **GitHub Actions** | CI/CD automation |
| **Sablier** | Scale-to-zero for cost savings on dev |

### What's Over-Engineered

#### Docker Swarm

**Current State:** 3-node Swarm cluster with complex worker registration.

**Problem:** For 3 servers running 5-10 services, Swarm adds:
- Worker registration dance (orchestration API)
- Token management
- Node labeling for placement
- Swarm reconciliation service
- GitHub App callbacks for worker joins

**Alternative:** Plain `docker compose` with `restart: always` provides:
- Same auto-restart on failure
- Same deployment automation
- 90% less complexity

#### Dokploy

**Current State:** Self-hosted PaaS for deployment management.

**Problem:** Dokploy has become a metadata database:
- Builds moved to GitHub Actions (Better Auth API issue)
- Deployments done via GitHub Actions → Dokploy API sync
- DNS managed by Cloudflare actions
- Traefik config managed by NixOS

**What Dokploy Actually Provides:**
- Web UI for viewing deployments
- Environment variable storage

**Alternative:** Direct SSH + compose deployment with:
- Env vars in GitHub Secrets
- Deployment history in GitHub Actions logs

#### Dual Traefik Modes

**Current State:** Two routing patterns:
- Centralized (Swarm services via admin-dokploy)
- Distributed (Compose on custom VPS)

**Problem:** Two mental models to understand and debug.

**Alternative:** Single file-provider mode everywhere.

#### 90+ GitHub Actions

**Current State:** Highly abstracted reusable actions.

**Problem:** Many actions are thin wrappers (3-5 lines of logic) creating indirection without value.

**Alternative:** Fewer, more comprehensive actions (10-15 total).

---

## Proposed Simplification

### Goals

1. **Keep all features** - Full automation, scale-to-zero, custom VPS
2. **Reduce complexity** - Fewer moving parts, easier debugging
3. **Maintain automation level** - `git push` → deployed

### Architecture Comparison

```
CURRENT DEPLOYMENT FLOW:
────────────────────────────────────────────────────────────
GitHub Actions (app-deploy.yml - 792 lines)
    ↓
Config load action (200 lines)
    ↓
Server resolve via Dokploy API
    ↓
Build image → Push to private registry
    ↓
Dokploy API sync
    ↓
Swarm service update
    ↓
Wait for Swarm reconciliation
    ↓
DNS update via Cloudflare
    ↓
Wildcard cert config
    ↓
Container running (finally)


SIMPLIFIED DEPLOYMENT FLOW:
────────────────────────────────────────────────────────────
GitHub Actions (deploy.yml - 50 lines)
    ↓
Tailscale connect
    ↓
SSH: docker compose pull && up -d
    ↓
Container running

Traefik auto-reloads via file provider.
DNS pre-configured or updated via simple action.
```

### Feature Parity

| Feature | Current | Simplified | Notes |
|---------|---------|------------|-------|
| git push → deployed | ✅ | ✅ | Same automation |
| Scale to zero | ✅ Sablier + Swarm | ✅ Sablier + Docker | Sablier has Docker provider |
| Custom VPS on-demand | ✅ Terraform | ✅ Terraform | Unchanged |
| Auto HTTPS | ✅ Traefik | ✅ Traefik | Unchanged |
| Zero manual intervention | ✅ | ✅ | Same level |
| Container auto-restart | ✅ Swarm | ✅ `restart: always` | Same result |

### What Gets Removed

| Component | Replacement |
|-----------|-------------|
| Docker Swarm | Plain Docker + compose |
| Dokploy | Direct SSH deployment |
| Orchestration API | Not needed without Swarm |
| Worker registration | Not needed without Swarm |
| Private registry | GitHub Container Registry (GHCR) |
| Dual Traefik modes | Single file-provider mode |

### What Stays

| Component | Why |
|-----------|-----|
| Terraform | Essential for IaC |
| Tailscale | Essential for secure access |
| Traefik | Essential for routing |
| Sablier | Valuable for scale-to-zero |
| NixOS | Optional but good for reproducibility |
| GitHub Actions | Essential for CI/CD |

---

## Migration Path

### Phase 1: Proof of Concept (1 day)

Deploy one new app using simplified approach:

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: tailscale/github-action@v2
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:ci

      - name: Deploy
        run: |
          ssh -o StrictHostKeyChecking=no root@${{ vars.SERVER }} << 'EOF'
            cd /apps/${{ github.event.repository.name }}
            docker compose pull
            docker compose up -d
          EOF
```

### Phase 2: Migrate Existing Apps (2-3 days)

1. Convert each app to simplified deployment
2. Test thoroughly
3. Remove old deployment path

### Phase 3: Remove Swarm (1 day)

```bash
# On each worker
docker swarm leave --force

# On manager
docker swarm leave --force

# Remove NixOS modules
# - swarm.nix
# - orchestration.nix
# - worker-registration.nix
```

### Phase 4: Remove Dokploy (1 day)

```bash
# Stop Dokploy
docker stack rm dokploy  # or docker compose down

# Remove NixOS modules
# - dokploy.nix
```

### Phase 5: Consolidate GitHub Actions (2-3 days)

Reduce from 90+ actions to 10-15 essential ones:
- `deploy-compose` - SSH + docker compose deployment
- `provision-vps` - Terraform VPS provisioning
- `traefik-config` - Deploy Traefik routing config
- `dns-update` - Cloudflare DNS management
- `ssl-setup` - Certificate configuration
- etc.

---

## Metrics

### Complexity Reduction

| Metric | Current | Simplified | Reduction |
|--------|---------|------------|-----------|
| Lines of infra code | ~5000 | ~1500 | -70% |
| GitHub Actions | 90+ | 10-15 | -85% |
| NixOS modules | 15 | 7-8 | -50% |
| Deployment paths | 3 | 1 | -67% |
| Services to understand | 12 | 5 | -60% |
| Debug time (avg) | 30-60 min | 5-10 min | -80% |

### Cost (Optional Consolidation)

| Setup | Servers | Monthly Cost |
|-------|---------|--------------|
| Current | 4 | ~31 EUR |
| Simplified (4 servers) | 4 | ~31 EUR |
| Consolidated (2 servers) | 2 | ~18 EUR |

---

## Decision Log

### 2026-02-05: Infrastructure Audit

**Context:** Infrastructure felt too complex for the actual workload.

**Finding:** Features are valuable (automation, scale-to-zero), but implementation is over-engineered. Swarm and Dokploy add complexity without proportional value for a small team.

**Decision:** Plan simplification while maintaining feature parity.

**Next Steps:**
1. POC simplified deployment on test project
2. If successful, migrate existing apps incrementally
3. Remove Swarm and Dokploy once all apps migrated

---

## References

- [Traefik Routing Architecture](./traefik-routing.md)
- [Dokploy Configuration](../config/dokploy-defaults.toml)
- [App Deploy Workflow](../.github/workflows/app-deploy.yml)
