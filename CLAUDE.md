# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **reusable GitHub Actions repository** for NextNode projects. It provides centralized CI/CD workflows and composite actions for consistent automation across all NextNode repositories.

**Key principle**: **pnpm only** - This repository exclusively uses pnpm as the package manager. No npm or yarn support.

## Architecture

### Current Repository Structure
```
github-actions/
├── .github/workflows/              # Reusable workflows (external + internal)
│   ├── quality-checks.yml         # Full quality pipeline (workflow_call)
│   ├── app-deploy.yml             # App deployment - composes atomic actions (workflow_call)
│   ├── release.yml                # NPM library release (workflow_call)
│   ├── publish-release.yml        # Publish workflow with repository_dispatch
│   ├── version-management.yml     # Automated versioning with changesets
│   ├── security.yml               # Security scanning (workflow_call)
│   ├── health-check.yml           # Health monitoring (workflow_call)
│   └── [additional workflows]     # Lint, test, typecheck individual workflows
├── lib/                            # Shared Python utilities
│   └── dokploy/                   # Dokploy deployment utilities
│       ├── __init__.py            # Package exports
│       ├── config.py              # deep_merge(), load_toml(), get_environment_config()
│       ├── domain.py              # compute_domain(), compute_url(), compute_app_name()
│       ├── port.py                # read_env_file(), detect_port(), get_port()
│       └── output.py              # output() helper for GITHUB_OUTPUT
├── actions/                        # Domain-organized atomic actions
│   ├── app/                       # App Deployment domain (atomic actions)
│   │   ├── config-load/           # Load and merge TOML configuration
│   │   ├── domain-generate/       # Compute environment-specific domain
│   │   ├── port-detect/           # Detect port from .env/Dockerfile
│   │   ├── dokploy-auth/          # Authenticate with Dokploy API
│   │   ├── dokploy-project-sync/  # Create/get Dokploy project
│   │   ├── dokploy-environment-sync/ # Create/get Dokploy environment
│   │   ├── dokploy-app-sync/      # Create/update Dokploy application
│   │   ├── dokploy-compose-sync/  # Create/update Dokploy compose stack
│   │   ├── dokploy-cleanup/       # Cleanup preview deployments
│   │   └── server-resolve/        # Resolve server ID and IPs
│   ├── build/                     # Build & Setup domain
│   │   ├── install/               # Dependency installation
│   │   ├── build-project/         # Project building
│   │   ├── docker-build-push/     # Build and push Docker images
│   │   └── smart-cache/           # Intelligent caching
│   ├── quality/                   # Code Quality domain
│   │   ├── lint/                  # ESLint checks
│   │   ├── typecheck/             # TypeScript validation
│   │   └── security-audit/        # Security scanning
│   ├── deploy/                    # Deployment Infrastructure domain
│   │   ├── cross-swarm-routing/   # Configure cross-swarm Traefik routing
│   │   ├── publish-service-port/  # Publish service port via socat
│   │   └── vps-provision/         # Auto-provision Hetzner VPS
│   ├── infrastructure/            # Infrastructure Integrations domain
│   │   ├── cloudflare-dns-upsert/ # Create/update DNS records
│   │   ├── tailscale-oauth/       # Tailscale OAuth token management
│   │   ├── tailscale-dokploy-url/ # Get Dokploy URL via Tailscale
│   │   ├── tailscale-device-cleanup/ # Cleanup Tailscale devices
│   │   └── dokploy-init-workers/  # Initialize Dokploy workers
│   ├── release/                   # NPM Release Management domain
│   │   ├── changesets-setup/      # Setup changesets for versioning
│   │   ├── changesets-version/    # Create version PRs with changesets
│   │   ├── changesets-publish/    # Publish packages with changesets
│   │   ├── changesets-pr-merge/   # Auto-merge version PRs
│   │   └── npm-provenance/        # NPM provenance attestation
│   ├── ssl/                       # SSL/TLS Configuration domain
│   │   └── cloudflare-ssl-setup/  # Cloudflare SSL/TLS mode configuration
│   ├── monitoring/                # Monitoring domain
│   │   └── check-job-results/     # Job result verification
│   ├── utilities/                 # Generic Utilities domain
│   │   ├── log-step/              # Enhanced logging
│   │   ├── run-command/           # Command wrapper
│   │   ├── check-command/         # Command availability check
│   │   ├── set-env-vars/          # Environment management
│   │   └── should-run/            # Conditional logic
│   ├── node-setup-complete/       # Global: Complete Node.js setup (used externally)
│   ├── test/                      # Global: Test execution (used externally)
│   └── health-check/              # Global: URL health monitoring (used externally)
└── README.md                       # User documentation
```

### Design Principles

1. **Domain Organization**: Actions are grouped by functional domain for better navigation
2. **Atomic Actions**: Each action in `/actions/` does ONE thing well
3. **Global Actions Preservation**: `test/` and `health-check/` remain at root for external compatibility
4. **No Package Manager Conditionals**: pnpm is hardcoded everywhere - no switches or alternatives
5. **Workflow Isolation**:
   - External workflows use `workflow_call` trigger only
   - Internal validation uses actionlint (lightweight, single job)
6. **Maximum Reusability**: Actions can be used individually or composed
7. **DRY Principle**: No code duplication, shared logic in atomic actions
8. **Clean Logging**: All actions use GitHub groups and timing metrics

### Domain Organization Philosophy

The actions are organized into logical domains to improve maintainability and discoverability:

- **app/**: Atomic actions for app deployment - config loading, Dokploy API interactions, server resolution
- **build/**: Everything related to project setup, dependency installation, building, and Docker image creation
- **quality/**: Code quality checks including linting, type checking, and security
- **deploy/**: Deployment infrastructure - cross-swarm routing, port publishing, VPS provisioning
- **infrastructure/**: Tailscale VPN, Cloudflare DNS, and other infrastructure integrations
- **release/**: NPM package release management with changesets and provenance
- **ssl/**: SSL/TLS configuration and certificate management
- **monitoring/**: Health checks and job result verification
- **utilities/**: Generic helper actions used across domains
- **Root level**: Only globally-used actions that external projects depend on

### Shared Python Library (lib/dokploy/)

The `lib/dokploy/` directory contains shared Python utilities used by multiple actions:
- **config.py**: `deep_merge()`, `load_toml()`, `load_merged_config()`, `get_project_name()`, `get_environment_config()`
- **domain.py**: `compute_domain()`, `compute_url()`, `compute_app_name()`, `is_sub_subdomain()`
- **port.py**: `read_env_file()`, `detect_port()`, `get_port()`
- **output.py**: `output()` helper for GitHub Actions output

## Infrastructure Integration

### How github-actions Connects to Infrastructure

This repository is the CI/CD component of NextNode's self-hosted platform. It works with the [infrastructure](https://github.com/nextnodesolutions/infrastructure) repository.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          DEPLOYMENT FLOW                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  github-actions                     infrastructure                  │
│  ┌─────────────────────┐           ┌─────────────────────┐         │
│  │ app-deploy.yml  │           │ terraform/          │         │
│  │   │                 │           │   ├── main.tf       │         │
│  │   ├── build         │           │   └── modules/      │         │
│  │   │   └── push ─────┼──────────>│       └── hetzner   │         │
│  │   │       (registry)│           │                     │         │
│  │   ├── sync          │           │ packer/             │         │
│  │   │   └── Dokploy   │           │   └── files/        │         │
│  │   ├── dns           │           │       └── NixOS     │         │
│  │   └── routing       │           │                     │         │
│  └─────────────────────┘           └─────────────────────┘         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

| Integration Point | github-actions Component | infrastructure Component |
|-------------------|--------------------------|--------------------------|
| Docker Registry | `build/docker-build-push` | NixOS Docker module |
| VPS Provisioning | `deploy/vps-provision` | Terraform hetzner-vps module |
| Cross-Swarm Routing | `deploy/cross-swarm-routing` | Traefik NixOS module |
| DNS Management | `infrastructure/cloudflare-dns-upsert` | Cloudflare Terraform provider |

### Registry-Only Mode (INT-149)

Dokploy v0.25+ uses Better Auth and no longer supports API-based builds. The deployment flow now:

1. **Build locally** in GitHub Actions runner
2. **Push to private registry** at `admin-dokploy:5000` via Tailscale
3. **Sync configuration** to Dokploy API (project, app, env vars)
4. **Set image reference** - Dokploy pulls from registry

This is handled by the `build/docker-build-push` action and `deploy/dokploy-sync` action.

## Deployment Architecture

### Dokploy Deployment

NextNode uses Dokploy (self-hosted PaaS) for application deployment:

- **dokploy-sync**: Syncs `dokploy.toml` configuration to Dokploy API
- **vps-provision**: Auto-provisions Hetzner VPS when project uses `server = "custom"`

### Cross-Swarm Routing Pattern

Apps deployed on worker nodes (dev-worker, prod-worker) need routing through Traefik on admin-dokploy:

1. **Port Publishing**: Container port exposed on worker via `socat`
2. **Traefik Config**: TCP route from admin-dokploy to worker:port
3. **DNS**: A record points to admin-dokploy (Traefik server)

This is handled automatically by `deploy/cross-swarm-routing` and `deploy/publish-service-port`.

### Scale-to-Zero (Sablier)

Development and preview environments use Sablier for automatic scale-to-zero:

| Setting | Default | Purpose |
|---------|---------|---------|
| `idle_timeout` | 30m | Time before scaling to 0 replicas |
| `session_duration` | 30m | Keep-alive time after wake |
| `startup_timeout` | 2m | Max wait for container to start |
| `theme` | hacker-terminal | Loading page theme |

**Environment defaults:**
- Development: `scale_to_zero = true`, lighter resources (128Mi/0.1 CPU)
- Preview: `scale_to_zero = true`, lighter resources (128Mi/0.1 CPU)
- Production: No scale-to-zero, standard resources (512Mi/0.5 CPU)

**Override per environment:**
```toml
[environments.development]
scale_to_zero = false  # Disable for always-on dev
```

### VPS Auto-Provisioning (INT-28)

Projects can request a dedicated VPS by setting `server = "custom"` in `dokploy.toml`:

```toml
[vps]
enabled = true
type = "cpx21"

[environments.production]
server = "custom"          # Triggers VPS provisioning
```

The `vps-provision` action calls the infrastructure repo's Terraform module to create the VPS.

## Usage Patterns

### For External Projects

External projects can call workflows in two ways:

1. **Full pipelines** (reusable workflows):
```yaml
uses: nextnodesolutions/github-actions/.github/workflows/quality-checks.yml@main
uses: nextnodesolutions/github-actions/.github/workflows/app-deploy.yml@main
uses: nextnodesolutions/github-actions/.github/workflows/release.yml@main
uses: nextnodesolutions/github-actions/.github/workflows/version-management.yml@main
```

2. **Individual actions**:

**Global actions (root level - always accessible):**
```yaml
uses: nextnodesolutions/github-actions/actions/node-setup-complete@main
uses: nextnodesolutions/github-actions/actions/test@main
uses: nextnodesolutions/github-actions/actions/health-check@main
```

**Domain-specific actions (NextNode internal projects only):**
```yaml
# Build domain
uses: nextnodesolutions/github-actions/actions/build/install@main

# Quality domain
uses: nextnodesolutions/github-actions/actions/quality/lint@main
uses: nextnodesolutions/github-actions/actions/quality/typecheck@main

# Deploy domain
uses: nextnodesolutions/github-actions/actions/deploy/dokploy-sync@main

# SSL domain
uses: nextnodesolutions/github-actions/actions/ssl/cloudflare-ssl-setup@main

# Release domain
uses: nextnodesolutions/github-actions/actions/release/changesets-publish@main
```

### For This Repository

Internal testing uses `internal-tests.yml` with manual trigger only to avoid recursion.

## Important Notes for Development

### When Adding New Actions
1. **Choose appropriate domain**: Place in correct domain folder (`build/`, `quality/`, `deploy/`, `ssl/`, `monitoring/`, `utilities/`)
2. Create a new folder in `/actions/{domain}/` with descriptive name
3. Add `action.yml` (not `action.yaml`)
4. Use inputs with sensible defaults
5. Add logging with `::group::` and `::endgroup::`
6. Include timing information
7. Document inputs/outputs clearly
8. **Never add to root level** unless it's globally used by external projects

### When Modifying Workflows
1. External workflows must use `workflow_call` trigger
2. Internal workflows must use `workflow_dispatch` or manual triggers
3. Never add push/pull_request triggers to avoid recursion
4. Use atomic actions from `/actions/` - don't duplicate logic

### Testing Changes

Internal validation is handled by `internal-tests.yml` which:
- Runs **actionlint** for YAML/workflow validation
- Validates action.yml structure (required fields)
- Triggers on PRs to main (when actions/workflows change)
- Can be manually triggered via workflow_dispatch

**Local testing:**
```bash
# Install actionlint for local validation
brew install actionlint

# Run actionlint locally (same as CI)
actionlint

# Test workflow with act (optional)
act workflow_dispatch -W .github/workflows/internal-tests.yml
```

## Common Tasks

### Adding a New Atomic Action
```bash
# Choose appropriate domain first
mkdir actions/utilities/my-new-action
touch actions/utilities/my-new-action/action.yml
# Add action logic using existing patterns
```

### Domain Selection Guide
- **build/**: Installation, building, caching, Docker image creation
- **quality/**: Linting, type checking, testing, security audits
- **deploy/**: Dokploy deployment, VPS provisioning, cross-swarm routing
- **infrastructure/**: Tailscale, Cloudflare DNS, worker initialization
- **release/**: NPM package release management, changesets, provenance
- **ssl/**: SSL/TLS configuration and certificate management
- **monitoring/**: Health checks, job verification
- **utilities/**: Generic helpers and tools
- **Global level**: Complete setups and externally-used actions

### Testing Actions Locally
```bash
# Run actionlint for YAML validation
actionlint

# Optionally use act for full workflow simulation
act workflow_dispatch -W .github/workflows/internal-tests.yml
```

### Debugging Workflow Issues
1. Check workflow syntax
2. **Verify action paths**: Use domain-based paths (e.g., `actions/build/install`, not `actions/install`)
3. **Global actions**: Only `test/` and `health-check/` are at root level
4. Ensure proper trigger configuration
5. Review logs with expanded groups

## Migration Notes

### Latest Migration: Internal Tests Optimization (2025-01)
Replaced inefficient 53-job matrix system with single actionlint job:
- **Problem**: `internal-tests.yml` consumed 1953 minutes/month (71% of total) with 53 parallel jobs per push
- **Root Cause**: Static validation tests running as matrix jobs, billed as 53+ minutes minimum per run
- **Solution**: Replaced with single actionlint job (~1 minute per run)
- **Removed**: Unused test utilities (`comprehensive-test`, `action-discovery`, `architecture-validator`, `reference-validator`, `test-summary`)
- **Trigger Change**: Now runs on PRs to main (with path filters) + manual dispatch, NOT on every push
- **Savings**: ~99% reduction in CI minutes

### Previous Migrations
- Migrated from Railway to Dokploy (self-hosted PaaS)
- Removed: workflow-templates/, packs/, internal/ directories
- Removed: Fly.io deployment support
- Removed: npm/yarn support
- Simplified: Action paths (removed unnecessary nesting)

## Dependencies

- **pnpm**: Version 10.12.4+ required
- **Node.js**: Version 20+ recommended
- **Docker**: For containerized deployments

## Security Considerations

1. All secrets must be passed explicitly - no hardcoded values
2. Use environment-specific secrets
3. Security audit runs on all quality checks
4. Docker images use non-root users

## Performance Optimizations

1. Dependency caching enabled by default
2. Parallel job execution where possible
3. Conditional steps to skip unnecessary work
4. Artifact compression for faster uploads

## Troubleshooting

### Common Issues

1. **"Action not found"**: Check path - use domain-based paths like `actions/build/install`, not `actions/install`
2. **"Workflow not accessible"**: Ensure using `workflow_call` trigger
3. **"pnpm not found"**: Always use `actions/node-setup-complete` action first
4. **"Global action moved"**: Only `node-setup-complete/`, `test/` and `health-check/` remain at root level

### Debug Mode

Enable debug logging by setting repository secret:
- `ACTIONS_RUNNER_DEBUG: true`
- `ACTIONS_STEP_DEBUG: true`

## Secrets and Tokens Guide (CRITICAL)

This section is essential for understanding how secrets flow through workflows. **Read this before modifying any workflow.**

### Token Types and When to Use Each

| Token Type | Source | Scope | Use Case |
|------------|--------|-------|----------|
| `github.token` | Automatic | Current repo | Default operations, checkouts, API calls |
| `secrets.GITHUB_TOKEN` | Automatic | Current repo | Same as above (prefer `github.token`) |
| GitHub App Token | Generated via action | Cross-repo | Infrastructure dispatch, cross-repo access |
| OAuth-derived tokens | Generated via action | External service | Tailscale API, Dokploy API |

**Rule**: Prefer `github.token` over `secrets.GITHUB_TOKEN` for consistency. They are identical.

### Secrets Declaration in workflow_call Workflows (MANDATORY)

**All reusable workflows MUST declare secrets explicitly** in the `on.workflow_call.secrets` block:

```yaml
on:
  workflow_call:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: string
    secrets:
      TAILSCALE_OAUTH_CLIENT_ID:
        description: 'Tailscale OAuth client ID'
        required: true
      TAILSCALE_OAUTH_SECRET:
        description: 'Tailscale OAuth client secret'
        required: true
      CLOUDFLARE_API_TOKEN:
        description: 'Cloudflare API token for DNS'
        required: false  # Optional secrets use required: false
```

**Why explicit declaration**:
1. Validation at workflow call time
2. Clear documentation of requirements
3. Type-safe secret passing
4. Easier debugging when secrets are missing

### Tailscale OAuth Pattern (CRITICAL - NO STATIC AUTH KEY)

**There is NO `TAILSCALE_AUTH_KEY` secret. Auth keys are generated dynamically.**

```yaml
# WRONG - This secret does NOT exist
- uses: tailscale/github-action@v2
  with:
    authkey: ${{ secrets.TAILSCALE_AUTH_KEY }}  # NEVER DO THIS

# CORRECT - Generate auth key via OAuth
- name: Get Tailscale Auth Key
  id: tailscale-oauth
  uses: nextnodesolutions/github-actions/actions/infrastructure/tailscale-oauth@main
  with:
    oauth-client-id: ${{ secrets.TAILSCALE_OAUTH_CLIENT_ID }}
    oauth-secret: ${{ secrets.TAILSCALE_OAUTH_SECRET }}
    generate-auth-key: 'true'
    auth-key-ephemeral: 'true'  # Recommended for CI

- name: Setup Tailscale
  uses: tailscale/github-action@v2
  with:
    authkey: ${{ steps.tailscale-oauth.outputs.auth-key }}
```

**OAuth Action Outputs**:
| Output | Description | Use Case |
|--------|-------------|----------|
| `api-token` | OAuth access token | Tailscale API calls (device management, DNS) |
| `auth-key` | Ephemeral auth key | Device registration (tailscale/github-action) |
| `success` | Boolean success flag | Conditional logic |

### Job Permissions for Tag/Release Operations

Jobs that push tags or create releases need explicit permissions:

```yaml
jobs:
  tag:
    runs-on: ubuntu-latest
    permissions:
      contents: write  # Required for git push, tag creation
    steps:
      - uses: actions/checkout@v4
      - run: |
          git tag v1.0.0
          git push origin v1.0.0

  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write  # Required for NPM provenance
```

### Complete Secrets Reference

| Secret | Used By Workflows | Purpose | Required |
|--------|-------------------|---------|----------|
| `TAILSCALE_OAUTH_CLIENT_ID` | app-deploy, infra-healthcheck, swarm-rollback, terraform-plan | Tailscale OAuth | Yes |
| `TAILSCALE_OAUTH_SECRET` | app-deploy, infra-healthcheck, swarm-rollback, terraform-plan | Tailscale OAuth | Yes |
| `DOKPLOY_ADMIN_EMAIL` | app-deploy | Dokploy API authentication | Yes (deploy) |
| `DOKPLOY_ADMIN_PASSWORD` | app-deploy | Dokploy API authentication | Yes (deploy) |
| `CLOUDFLARE_API_TOKEN` | dns, terraform-apply, app-deploy | DNS management | Yes (DNS) |
| `CLOUDFLARE_ZONE_ID` | dns | Zone ID (auto-lookup if not provided) | No |
| `HETZNER_TOKEN` | terraform-plan, terraform-apply, packer-build, app-deploy | Hetzner Cloud API | Yes (infra) |
| `TF_API_TOKEN` | terraform-plan, terraform-apply, app-deploy | Terraform Cloud state | Yes (infra) |
| `NPM_TOKEN` | release, publish-release | NPM publishing | Yes (release) |
| `CHANGESET_GITHUB_TOKEN` | release | GitHub access (fallback: GITHUB_TOKEN) | No |
| `NEXTNODE_APP_ID` | app-deploy, publish-release | GitHub App for cross-repo | Conditional |
| `NEXTNODE_APP_PRIVATE_KEY` | app-deploy, publish-release | GitHub App private key | Conditional |

### Token Derivation Chains

#### Tailscale OAuth Chain
```
TAILSCALE_OAUTH_CLIENT_ID + TAILSCALE_OAUTH_SECRET
    │
    ▼ tailscale-oauth action
    │
    ├── api-token → Tailscale API calls
    └── auth-key → Device registration (ephemeral)
```

#### Dokploy Authentication Chain
```
DOKPLOY_ADMIN_EMAIL + DOKPLOY_ADMIN_PASSWORD
    │
    ▼ dokploy-auth action
    │
    └── token → All Dokploy API calls
```

#### GitHub App Token Chain
```
NEXTNODE_APP_ID + NEXTNODE_APP_PRIVATE_KEY
    │
    ▼ actions/create-github-app-token@v1
    │
    └── token → Cross-repo operations (infrastructure dispatch)
```

### Common Mistakes to Avoid

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| `secrets.TAILSCALE_AUTH_KEY` | Secret doesn't exist | Use tailscale-oauth action |
| Missing secrets declaration | No validation, unclear requirements | Declare in workflow_call.secrets |
| `secrets.GITHUB_TOKEN` | Inconsistent | Use `github.token` |
| Missing permissions block | Tag/release operations fail | Add `permissions: contents: write` |
| Hardcoded tokens | Security risk | Always use secrets or generated tokens |
| Using `secrets: inherit` | Over-privileges jobs | Explicit secret passing |

### When Adding New Workflows

Checklist for secrets:
- [ ] Declare all required secrets in `on.workflow_call.secrets`
- [ ] Add descriptions for each secret
- [ ] Mark optional secrets with `required: false`
- [ ] Document in this CLAUDE.md secrets table
- [ ] Use `github.token` not `secrets.GITHUB_TOKEN`
- [ ] Add `permissions` block if creating tags/releases
- [ ] Use tailscale-oauth action (never static TAILSCALE_AUTH_KEY)
