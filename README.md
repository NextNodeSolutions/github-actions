# NextNode GitHub Actions

> Reusable GitHub Actions and workflows for NextNode projects - **pnpm only**

## Table of Contents

- [Quick Start](#quick-start)
- [Infrastructure Architecture](#infrastructure-architecture)
- [Deployment Flow](#deployment-flow)
- [dokploy.toml Configuration](#dokploytoml-configuration)
- [Secrets Reference](#secrets-reference)
- [Available Actions](#available-actions)
- [Available Reusable Workflows](#available-reusable-workflows)
- [Troubleshooting](#troubleshooting)

## Repository Structure

```
github-actions/
├── .github/workflows/          # Reusable workflows (external + internal)
│   ├── quality-checks.yml     # Full quality pipeline (workflow_call)
│   ├── dokploy-deploy.yml     # Dokploy deployment (workflow_call)
│   ├── release.yml            # NPM library release (workflow_call)
│   ├── publish-release.yml    # Publish workflow with repository_dispatch
│   ├── version-management.yml # Automated versioning with changesets
│   └── [additional workflows] # Security, health checks, etc.
├── actions/                    # Domain-organized atomic actions
│   ├── build/                 # Build & Setup domain (install, build-project, docker-build-push)
│   ├── quality/               # Code Quality domain
│   ├── deploy/                # Dokploy Deployment domain (dokploy-sync, cross-swarm-routing)
│   ├── infrastructure/        # Infrastructure domain (cloudflare-dns, tailscale)
│   ├── release/               # NPM Release Management domain
│   ├── ssl/                   # SSL/TLS Configuration domain
│   ├── monitoring/            # Monitoring domain
│   ├── utilities/             # Generic Utilities domain
│   ├── node-setup-complete/   # Global: Complete Node.js setup
│   ├── test/                  # Global: Test execution
│   └── health-check/          # Global: URL health monitoring
├── config/
│   └── dokploy-defaults.toml  # Default configuration values
```

## Quick Start

### Using Global Actions

Global actions are available at the root level for external projects.

```yaml
# Complete Node.js and pnpm setup with caching (auto-detects versions)
- name: Setup Node.js and pnpm
  uses: nextnodesolutions/github-actions/actions/node-setup-complete@main

- name: Run Tests
  uses: nextnodesolutions/github-actions/actions/test@main
  with:
    coverage: true
    coverage-threshold: '80'

- name: Health Check
  uses: nextnodesolutions/github-actions/actions/health-check@main
  with:
    url: 'https://my-app.example.com'
    max-attempts: 5
```

## Version Auto-Detection

All workflows and actions automatically detect Node.js and pnpm versions from your project's configuration. **No version inputs required!**

### How it works

**pnpm Version**: Automatically detected from `packageManager` field in `package.json`:
```json
{
  "packageManager": "pnpm@10.11.0"
}
```

**Node.js Version**: Automatically detected from `engines.node` field in `package.json`:
```json
{
  "engines": {
    "node": ">=20.0.0"
  }
}
```

### Benefits

- **Single source of truth** - Versions defined in one place
- **No version conflicts** - Local and CI environments always match
- **Easy maintenance** - Update `package.json` and everywhere stays in sync
- **Corepack compatible** - Works with modern Node.js toolchain

## Infrastructure Architecture

The github-actions repository is the CI/CD component of NextNode's self-hosted deployment platform. It works in conjunction with the [infrastructure](https://github.com/nextnodesolutions/infrastructure) repository.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     NEXTNODE CI/CD ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐         ┌──────────────────┐                 │
│  │  Your App Repo   │         │  github-actions  │                 │
│  │                  │  uses   │                  │                 │
│  │  - Source code   │────────>│  - Workflows     │                 │
│  │  - dokploy.toml  │         │  - Actions       │                 │
│  │  - Dockerfile    │         │  - Defaults      │                 │
│  └──────────────────┘         └────────┬─────────┘                 │
│                                        │                            │
│                    ┌───────────────────┼───────────────────┐       │
│                    │                   ▼                    │       │
│                    │          Docker Build & Push           │       │
│                    │        (via Tailscale to Registry)     │       │
│                    │                   │                    │       │
│                    │                   ▼                    │       │
│  ┌─────────────────┴───────────────────┴────────────────────┴──┐   │
│  │                    HETZNER CLOUD CLUSTER                     │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐             │   │
│  │  │   Admin    │  │    Dev     │  │    Prod    │             │   │
│  │  │  Dokploy   │  │   Worker   │  │   Worker   │             │   │
│  │  │  Traefik   │  │            │  │            │             │   │
│  │  │  Registry  │  │  PR/Dev    │  │ Production │             │   │
│  │  └────────────┘  └────────────┘  └────────────┘             │   │
│  │       ▲              ▲                ▲                      │   │
│  │       └──────────────┴────────────────┘                      │   │
│  │                  Tailscale VPN                               │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  DNS: Cloudflare (auto-configured)                                  │
│  SSL: Let's Encrypt via Traefik DNS-01                             │
└─────────────────────────────────────────────────────────────────────┘
```

### Server Roles

| Server | Role | Description |
|--------|------|-------------|
| `admin-dokploy` | Control Plane | Dokploy UI, Docker Registry (port 5000), Traefik ingress |
| `dev-worker` | Development | PR preview deployments, development environment |
| `prod-worker` | Production | Production applications |

### Key Integration Points

| Component | Repository | Purpose |
|-----------|------------|---------|
| VPS Provisioning | infrastructure | Terraform modules for Hetzner VPS |
| NixOS Configuration | infrastructure | Server OS and services configuration |
| Dokploy Sync | github-actions | API calls to configure Dokploy |
| Docker Build | github-actions | Build and push to private registry |
| DNS Management | github-actions | Cloudflare DNS record automation |

### Network Topology

- **Tailscale VPN**: All servers communicate via Tailscale mesh network
- **Registry Access**: Private registry (`admin-dokploy:5000`) accessible only via Tailscale
- **Traefik Routing**: All public traffic enters through Traefik on admin-dokploy
- **Cross-Swarm**: Apps on worker nodes are proxied via Traefik TCP routing

## Deployment Flow

When you push code or trigger a deployment, this is what happens:

```
1. Push to Repository
        │
        ▼
2. Quality Checks (lint, typecheck, test, build)
        │
        ▼
3. Docker Build
   ├── Connect to Tailscale VPN
   ├── Build Docker image
   └── Push to admin-dokploy:5000/repo-name:sha
        │
        ▼
4. Dokploy Sync
   ├── Create/update project in Dokploy
   ├── Create/update application
   ├── Configure environment variables
   └── Set Docker image reference
        │
        ▼
5. DNS Configuration
   ├── Get target server IP (Traefik server)
   └── Upsert Cloudflare A record
        │
        ▼
6. Cross-Swarm Routing (if app on worker)
   ├── Allocate external port on worker
   ├── Expose container port via socat
   └── Configure Traefik TCP route
        │
        ▼
7. Health Check
   └── Verify application responds at domain
```

### Environment-Based Deployment

| Environment | Domain Pattern | Default Server | Auto-Deploy |
|-------------|---------------|----------------|-------------|
| `production` | `{domain}` | prod-worker | No (manual) |
| `development` | `dev.{domain}` | dev-worker | Yes |
| `preview` | `pr-{number}.dev.{domain}` | dev-worker | Yes |

### Using Reusable Workflows

Reusable workflows provide complete CI/CD pipelines.

```yaml
# Quality checks workflow
name: CI

on: [push, pull_request]

jobs:
  quality:
    uses: nextnodesolutions/github-actions/.github/workflows/quality-checks.yml@main
    with:
      test-coverage: true
      run-security: true
```

```yaml
# NPM library release workflow
name: Release

on:
  workflow_dispatch:

jobs:
  release:
    uses: nextnodesolutions/github-actions/.github/workflows/release.yml@main
    with:
      run-quality-checks: true
      enable-provenance: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Available Actions

### Global Actions (External Use)

| Action | Description | Key Inputs |
|--------|-------------|------------|
| `node-setup-complete` | Complete Node.js and pnpm setup with caching | Auto-detects versions from package.json |
| `test` | Run tests with optional coverage | `coverage`, `coverage-threshold`, `test-script` |
| `health-check` | Check URL health status | `url`, `max-attempts`, `expected-status` |

### Domain Actions (Internal Use)

#### Build Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `build/install` | Install dependencies with pnpm | `frozen-lockfile`, `working-directory` |
| `build/build-project` | Build project with pnpm | `build-command`, `output-directory` |
| `build/smart-cache` | Intelligent dependency caching | `cache-key`, `restore-keys` |

#### Quality Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `quality/lint` | Run ESLint with optional auto-fix | `fix`, `fail-on-warning` |
| `quality/typecheck` | Run TypeScript type checking | `strict`, `tsconfig-path` |
| `quality/security-audit` | Run security audit | `audit-level`, `fix` |

#### Build Domain (Additional)
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `build/docker-build-push` | Build and push Docker image to registry | `dockerfile`, `context`, `build-args` |

#### Deploy Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `deploy/dokploy-sync` | Sync dokploy.toml to Dokploy API | `environment`, `config-file` |
| `deploy/vps-provision` | Auto-provision Hetzner VPS | `vps-name`, `server-type` |
| `deploy/cross-swarm-routing` | Configure Traefik routing for worker nodes | `domain`, `worker-tailscale-ip` |
| `deploy/publish-service-port` | Expose container port via socat | `container-port`, `external-port` |

#### Infrastructure Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `infrastructure/cloudflare-dns-upsert` | Create/update Cloudflare DNS records | `domain`, `content`, `proxied` |
| `infrastructure/tailscale-oauth` | Get Tailscale API token via OAuth | `oauth-client-id`, `oauth-secret` |
| `infrastructure/tailscale-dokploy-url` | Get Dokploy URL via Tailscale | `tailscale-oauth-client-id` |
| `infrastructure/tailscale-device-cleanup` | Clean up stale Tailscale devices | `tailscale-api-token` |
| `infrastructure/dokploy-init-workers` | Initialize Dokploy workers | `dokploy-url` |

#### Release Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `release/changesets-setup` | Setup changesets for versioning | `version`, `working-directory` |
| `release/changesets-version` | Create version PR with changesets | `version-script`, `commit-message` |
| `release/changesets-publish` | Publish packages with changesets | `publish-script`, `registry-url` |
| `release/npm-provenance` | Setup NPM provenance attestation | `token`, `package-name` |

#### Utility Actions
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `utilities/log-step` | Enhanced logging with groups | `title`, `message`, `level` |
| `utilities/set-env-vars` | Set environment variables | `variables`, `prefix` |
| `utilities/run-command` | Run shell commands | `command`, `working-directory` |
| `utilities/check-command` | Check if command exists | `command`, `fail-if-missing` |

## Available Reusable Workflows

### Quality Checks Workflow
**File:** `.github/workflows/quality-checks.yml`

Complete quality assurance workflow including:
- Linting
- Type checking
- Testing (with optional coverage)
- Building
- Security audit

**Example:**
```yaml
jobs:
  quality:
    uses: nextnodesolutions/github-actions/.github/workflows/quality-checks.yml@main
    with:
      run-lint: true
      run-typecheck: true
      run-tests: true
      run-build: true
      run-security: false
      test-coverage: true
      coverage-threshold: '80'
```

### Dokploy Deployment Workflow
**File:** `.github/workflows/dokploy-deploy.yml`

Unified deployment workflow for Dokploy (self-hosted PaaS).

**Features:**
- Environment-based configuration via `dokploy.toml`
- Quality checks before deployment
- Health checks after deployment
- Auto VPS provisioning for custom servers

**Example:**
```yaml
jobs:
  deploy:
    uses: nextnodesolutions/github-actions/.github/workflows/dokploy-deploy.yml@main
    with:
      environment: production
    secrets:
      DOKPLOY_TOKEN: ${{ secrets.DOKPLOY_TOKEN }}
```

## dokploy.toml Configuration

Projects configure their deployment via a `dokploy.toml` file in the repository root. Values not specified use defaults from [`config/dokploy-defaults.toml`](config/dokploy-defaults.toml).

### Minimal Configuration

```toml
[project]
name = "my-app"
domain = "myapp.com"
```

### Complete Reference

```toml
# =============================================================================
# PROJECT CONFIGURATION (required)
# =============================================================================
[project]
name = "my-app"               # Project name in Dokploy
domain = "myapp.com"          # Base domain for all environments

# =============================================================================
# BUILD CONFIGURATION
# =============================================================================
[build]
type = "dockerfile"           # dockerfile | nixpacks | buildpacks | static
dockerfile = "Dockerfile"     # Default: Dockerfile
context = "."                 # Docker build context
target = ""                   # Multi-stage build target (optional)

# =============================================================================
# RESOURCE LIMITS
# =============================================================================
[resources]
memory = "512Mi"              # Default memory request
cpu = 0.5                     # Default CPU request
memory_limit = "1Gi"          # Hard memory limit
cpu_limit = 1                 # Hard CPU limit

# =============================================================================
# HEALTH CHECKS
# =============================================================================
[healthcheck]
enabled = true
path = "/health"              # Health check endpoint
interval = 30                 # Seconds between checks
timeout = 10                  # Seconds before timeout
retries = 3                   # Failures before unhealthy
start_period = 40             # Startup grace period
rollback = true               # Auto-rollback on failure

# =============================================================================
# ENVIRONMENT OVERRIDES
# =============================================================================
[environments.development]
enabled = true                # Enable dev environment
server = "dev-worker"         # Target server
replicas = 1
auto_deploy = true

[environments.preview]
enabled = true                # Enable PR previews
server = "dev-worker"
cleanup_on_merge = true       # Delete preview on PR merge

[environments.production]
server = "prod-worker"        # Default production server
replicas = 1
auto_deploy = false           # Manual deploy for production

# =============================================================================
# CUSTOM VPS (dedicated server for this project)
# =============================================================================
[vps]
enabled = true                # Request dedicated VPS
type = "cpx21"                # Hetzner: cpx11, cpx21, cpx31, cpx41, cpx51
location = "fsn1"             # fsn1, nbg1, hel1

# When [vps] is enabled for production, set:
[environments.production]
server = "custom"             # Triggers VPS provisioning
```

### Common Scenarios

**Simple App (dev + production)**:
```toml
[project]
name = "my-api"
domain = "api.example.com"
```

**Production Only (no dev/preview)**:
```toml
[project]
name = "landing-page"
domain = "example.com"

[environments.development]
enabled = false

[environments.preview]
enabled = false
```

**High-Traffic App (dedicated VPS)**:
```toml
[project]
name = "main-app"
domain = "app.example.com"

[vps]
enabled = true
type = "cpx31"

[environments.production]
server = "custom"
replicas = 2

[resources]
memory = "2Gi"
cpu = 2
```

## Secrets Reference

Secrets required for the deployment workflow:

| Secret | Workflow | Description | Required |
|--------|----------|-------------|----------|
| `DOKPLOY_ADMIN_EMAIL` | dokploy-deploy | Dokploy admin email | Yes |
| `DOKPLOY_ADMIN_PASSWORD` | dokploy-deploy | Dokploy admin password | Yes |
| `TAILSCALE_OAUTH_CLIENT_ID` | dokploy-deploy | Tailscale OAuth client ID | Yes |
| `TAILSCALE_OAUTH_SECRET` | dokploy-deploy | Tailscale OAuth secret | Yes |
| `CLOUDFLARE_API_TOKEN` | dokploy-deploy | Cloudflare DNS API token | Yes |
| `HETZNER_TOKEN` | dokploy-deploy | Hetzner Cloud API (for custom VPS) | For VPS |
| `TF_API_TOKEN` | dokploy-deploy | Terraform Cloud token (for custom VPS) | For VPS |
| `DOKPLOY_SSH_KEY_ID` | dokploy-deploy | SSH key ID for VPS registration | For VPS |
| `INFISICAL_CLIENT_ID` | dokploy-deploy | Infisical secrets (optional) | Optional |
| `INFISICAL_CLIENT_SECRET` | dokploy-deploy | Infisical secrets (optional) | Optional |
| `NPM_TOKEN` | release | NPM publishing token | For libs |
| `GITHUB_TOKEN` | release, version-management | GitHub API access | Yes |

### How to Obtain Secrets

- **DOKPLOY_***: Created during Dokploy setup on admin-dokploy
- **TAILSCALE_***: [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth) → OAuth clients
- **CLOUDFLARE_API_TOKEN**: [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens) → Zone:DNS Edit
- **HETZNER_TOKEN**: [Hetzner Cloud Console](https://console.hetzner.cloud/) → API tokens
- **TF_API_TOKEN**: [Terraform Cloud](https://app.terraform.io/app/settings/tokens) → User tokens
- **NPM_TOKEN**: [npmjs.com](https://www.npmjs.com/) → Access Tokens → Automation

### VPS Auto-Provisioning

Projects can request a dedicated VPS by configuring `dokploy.toml`:

```toml
[vps]
enabled = true
type = "cpx21"

[environments.production]
server = "custom"
```

When `server = "custom"` is set, the workflow automatically provisions a Hetzner VPS via Terraform before deployment. The VPS is:
- Named `{project-name}-worker`
- Configured with NixOS and Docker
- Joined to Tailscale network
- Registered as a Dokploy worker

### NPM Release Workflow
**File:** `.github/workflows/release.yml`

Complete NPM library release workflow with changesets.

**Features:**
- Automated versioning with changesets
- Quality checks before release
- NPM provenance attestation
- Security best practices

**Example:**
```yaml
jobs:
  release:
    uses: nextnodesolutions/github-actions/.github/workflows/release.yml@main
    with:
      run-quality-checks: true
      enable-provenance: true
      publish-script: 'changeset:publish'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Version Management Workflow
**File:** `.github/workflows/version-management.yml`

Automated version management with PR creation and auto-merge.

**Features:**
- Creates version PRs with changesets
- Auto-merges version PRs
- Triggers release workflow via repository_dispatch
- Configurable merge strategies

**Example:**
```yaml
jobs:
  version:
    uses: nextnodesolutions/github-actions/.github/workflows/version-management.yml@main
    with:
      auto-merge: true
      version-script: 'changeset:version'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration

### Default Values

Default values are defined directly in each action's `action.yml` file:

- **Node.js version**: `20`
- **pnpm version**: `10.12.4`
- **Audit level**: `high`
- **Working directory**: `.`
- **Timeouts**: 30s health checks, 15min deploys

### Environment-Based Settings

The deployment workflow automatically adjusts settings based on environment:

| Setting | Development | Production |
|---------|------------|------------|
| Memory | 512MB | 1024MB |
| Build Command | `build:dev` | `build` |
| Coverage Threshold | 60% | 80% |
| Fail on Warning | No | Yes |

## Testing

Internal testing is handled by the repository's own workflows.

To test workflows locally:

```bash
# Test using act (GitHub Actions local runner)
act workflow_dispatch -W .github/workflows/quality-checks.yml

# Run specific workflow
gh workflow run quality-checks.yml
```

## Requirements

- **Node.js:** v20+ recommended
- **pnpm:** v10.12.4+ required (npm and yarn are not supported)
- **GitHub Actions:** All workflows use GitHub-hosted runners

## Security

- All workflows use `pnpm audit` for security scanning
- Production deployments require passing security checks
- Automated dependency updates via Dependabot
- Secrets are never logged or exposed

## Contributing

1. Create atomic actions for single responsibilities
2. Use pnpm exclusively (no npm/yarn support)
3. Add comprehensive logging with GitHub Actions groups
4. Include timing information for performance tracking
5. Write clear documentation with examples
6. Test internally before external use

## Migration Guide

### From npm/yarn to pnpm

All workflows now use pnpm exclusively. Update your projects:

1. Remove `package-lock.json` or `yarn.lock`
2. Run `pnpm import` to generate `pnpm-lock.yaml`
3. Update all workflow files to use these actions
4. Remove any npm/yarn specific configurations

### From Old Workflow Structure

Update to use domain-organized actions and reusable workflows:

```yaml
# Old atomic actions (removed)
- uses: nextnodesolutions/github-actions/actions/atomic/lint@main

# New domain-organized actions
- uses: nextnodesolutions/github-actions/actions/quality/lint@main

# Or use complete workflows
- uses: nextnodesolutions/github-actions/.github/workflows/quality-checks.yml@main
```

## Best Practices

1. **Use Reusable Workflows:** Prefer complete workflows for common patterns
2. **Domain Organization:** Use domain-specific actions when building custom workflows
3. **Global Actions:** Use root-level actions for external projects
4. **Enable Caching:** Always enabled in `node-setup-complete` action
5. **Set Appropriate Timeouts:** Prevent hung workflows
6. **Use Groups for Logging:** All actions include grouped logging
7. **Fail Fast:** Exit early on errors
8. **Security First:** Use provenance attestation for NPM packages
9. **Automated Versioning:** Use changesets for semantic releases

## Troubleshooting

### Common Issues

**Issue:** Dependencies not installing
- **Solution:** Ensure `pnpm-lock.yaml` exists and is committed

**Issue:** Type check failing
- **Solution:** Verify `tsconfig.json` has `strict: true`

**Issue:** Coverage threshold not met
- **Solution:** Adjust threshold or improve test coverage

**Issue:** Deployment failing
- **Solution:** Check Dokploy credentials and configuration

### Deployment-Specific Issues

**Issue:** "Failed to connect to registry"
- **Cause:** Tailscale connection failed
- **Solution:** Verify `TAILSCALE_OAUTH_CLIENT_ID` and `TAILSCALE_OAUTH_SECRET` are correct

**Issue:** "Project not found in Dokploy"
- **Cause:** Project doesn't exist or name mismatch
- **Solution:** Check `[project].name` in `dokploy.toml` matches Dokploy

**Issue:** "DNS record not updated"
- **Cause:** Cloudflare token missing permissions
- **Solution:** Ensure token has `Zone:DNS:Edit` permission for the domain's zone

**Issue:** "Cross-swarm routing failed"
- **Cause:** Worker not reachable via Tailscale
- **Solution:** Verify worker is online in Tailscale admin, check `worker-tailscale-ip` output

**Issue:** "Health check failed after deployment"
- **Cause:** Application not responding on expected port/path
- **Solution:** Verify `[healthcheck].path` matches your app's health endpoint

**Issue:** "Sub-subdomain SSL not working"
- **Cause:** Cloudflare free SSL only covers `*.domain.com`, not `*.subdomain.domain.com`
- **Solution:** Sub-subdomains (e.g., `pr-5.dev.example.com`) use DNS-only mode, SSL handled by Traefik

### Debug Mode

Enable debug logging by setting repository secrets:
- `ACTIONS_RUNNER_DEBUG: true`
- `ACTIONS_STEP_DEBUG: true`

### Logs and Diagnostics

```bash
# Check Dokploy logs
ssh root@admin-dokploy
docker logs dokploy -f

# Check Traefik routing
ssh root@admin-dokploy
cat /var/lib/traefik/dynamic/*.yml

# Check container on worker
ssh root@dev-worker
docker ps | grep <app-name>
docker logs <container-id>

# Check Tailscale connectivity
tailscale ping admin-dokploy
```

## License

MIT NextNode Solutions

## Links

- [NextNode](https://nextnode.dev)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [pnpm Documentation](https://pnpm.io)
