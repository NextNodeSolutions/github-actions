# NextNode GitHub Actions

Reusable GitHub Actions workflows and composite actions for NextNode projects, providing consistent CI/CD automation with Railway deployment support.

## 🎯 Design Principles

- **DRY (Don't Repeat Yourself)**: Shared logic centralized in composite actions
- **KISS (Keep It Simple)**: Minimal complexity, maximum clarity
- **Single Responsibility**: Each action has one clear purpose
- **Composability**: Actions can be combined for complex workflows
- **Performance Optimized**: Fast CI/CD execution with smart caching

## 📁 Repository Structure

```
github-actions/
├── actions/                    # Composite actions (building blocks)
│   ├── setup-environment/     # Complete environment setup
│   ├── composite-pipeline/    # All-in-one pipeline with setup + quality
│   └── quality-pipeline/      # Optimized quality checks
├── config/                     # Configuration defaults
│   └── defaults.yml
├── workflow-templates/         # Template workflows
│   └── railway-cd.yml         # Railway CD template
└── .github/workflows/         # Reusable workflows
    ├── job-*.yml             # Individual job workflows
    └── pack-*.yml            # Workflow packs (combined jobs)
```

## ⚙️ Repository Setup

**No setup required!** This repository is public and workflows are immediately accessible to all repositories.

### Repository Status:
- ✅ **Public repository** - No access restrictions
- ✅ **Immediately usable** - No configuration needed
- ✅ **Community friendly** - Others can learn from your workflow patterns

## 🚀 Quick Start

### Railway Deployment (Recommended)

Copy the [railway-cd.yml](workflow-templates/railway-cd.yml) template to your project's `.github/workflows/` directory:

```bash
mkdir -p .github/workflows
curl -o .github/workflows/railway-cd.yml https://raw.githubusercontent.com/NextNodeSolutions/github-actions/main/workflow-templates/railway-cd.yml
```

### Required Secrets

Add these secrets to your repository or organization:

- **RAILWAY_API_TOKEN** - Your Railway account token for deployments

Optional secrets:
- **CLOUDFLARE_API_TOKEN** - For custom domain DNS management

### Example Usage

```yaml
# Development deployment
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-railway-dev.yml@main
with:
  app-name: "my-app"  # Creates: dev-my-app
  app-env: "DEV"
secrets:
  RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}

# Production deployment
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-railway-prod.yml@main
with:
  app-name: "my-app"  # Creates: prod-my-app
  domain: "myapp.com"
  app-env: "PROD"
secrets:
  RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

## 📦 Available Workflows

### Railway Deployment Packs

#### Development Deployment
```yaml
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-railway-dev.yml@main
with:
  app-name: "my-app"  # Creates: dev-my-app
  app-env: "DEV"
  variables: '{"NODE_ENV": "development"}'
secrets:
  RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

#### Production Deployment
```yaml
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-railway-prod.yml@main
with:
  app-name: "my-app"  # Creates: prod-my-app
  domain: "myapp.com"
  app-env: "PROD"
  memory-mb: "1024"
  variables: '{"NODE_ENV": "production"}'
secrets:
  RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

### Quality Checks
```yaml
uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@main
with:
  run-lint: true
  run-typecheck: true
  run-test: true
```

## 📋 Composite Actions

### `setup-environment`
Complete environment setup with Node.js, pnpm, and optional dependency installation.

```yaml
- uses: ./.github-actions/actions/setup-environment
  with:
    node-version: '20'        # default: '20'
    pnpm-version: '10.11.0'   # default: '10.11.0'
    install-deps: 'true'      # default: 'true'
    frozen-lockfile: 'true'   # default: 'true'
    working-directory: '.'    # default: '.'
```

### Railway Deployment
Use the reusable workflows instead of composite actions for Railway deployment:

```yaml
# Development deployment
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-railway-dev.yml@main
with:
  app-name: "my-app"
  variables: '{"NODE_ENV": "development"}'
secrets:
  RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

### `quality-pipeline`
Comprehensive quality checks including lint, type-check, test, and build.

```yaml
- uses: ./.github-actions/actions/quality-pipeline
  with:
    node-version: '20'        # default: '20'
    pnpm-version: '10.11.0'   # default: '10.11.0'
    skip-tests: 'false'       # default: 'false'
    skip-build: 'false'       # default: 'false'
    skip-audit: 'false'       # default: 'false'
    audit-level: 'high'       # default: 'high'
    working-directory: '.'    # default: '.'
```

## 📋 Legacy Workflow Reference

### Individual Jobs

#### `job-lint.yml`
Runs linting checks on your codebase.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `command` (default: 'pnpm lint')

#### `job-typecheck.yml`
Runs TypeScript type checking.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `command` (default: 'pnpm type-check')

#### `job-test.yml`
Runs tests with optional coverage.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `coverage` (default: false)
- `command` (default: automatic based on coverage)

#### `job-build.yml`
Builds the project with optional artifact upload.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `command` (default: 'pnpm build')
- `upload-artifact` (default: false)
- `artifact-name` (default: 'build-output')
- `artifact-path` (default: 'dist')

#### `job-security.yml`
Runs security audits and Docker scans.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `audit-level` (default: 'high')
- `docker-scan` (default: true)

#### `job-deploy-fly.yml`
Deploys to Fly.io with health checks and rollback.

**Inputs:**
- `environment` (required: 'development' or 'production')
- `app-name` (required)
- `fly-org` (required)
- `fly-config` (default: 'fly.toml')
- `health-check-url` (optional)
- `strategy` (default: 'rolling', options: 'rolling', 'bluegreen')
- `min-machines` (default: '1')
- `memory-mb` (default: '512')
- `checkout-ref` (optional)

**Secrets:**
- `FLY_API_TOKEN` (required)

**Outputs:**
- `fly-url`: Deployed application URL
- `deployed`: Deployment status

#### `job-deploy-railway.yml`
Deploys to Railway with project/service management and health checks.

**Inputs:**
- `environment` (required: 'development' or 'production')
- `app-name` (required) - Creates `${environment}-${app-name}` project
- `service-name` (optional, defaults to app-name)
- `health-check-url` (optional)
- `memory-mb` (default: '512')
- `app-env` (optional: LOCAL/DEV/PROD)
- `variables` (optional: JSON object for environment variables)
- `working-directory` (default: '.')

**Secrets:**
- `RAILWAY_API_TOKEN` (required)

**Outputs:**
- `railway-url`: Deployed application URL
- `project-id`: Railway project ID
- `service-id`: Railway service ID
- `deployed`: Deployment status

#### `job-dns-cloudflare.yml`
Manages DNS records via Cloudflare API.

**Inputs:**
- `domain` (required)
- `subdomain` (default: '', empty for root)
- `app-name` (required)
- `proxied` (default: true)
- `ttl` (default: 1)

**Secrets:**
- `FLY_API_TOKEN` (required)
- `CLOUDFLARE_API_TOKEN` (required)
- `CLOUDFLARE_ZONE_ID` (required)

**Outputs:**
- `dns-updated`: DNS update status
- `custom-url`: Custom domain URL

### Workflow Packs

#### `pack-quality-checks.yml`
Combined quality checks workflow.

**Inputs:**
- `run-lint` (default: true)
- `run-typecheck` (default: true)
- `run-test` (default: true)
- `run-build` (default: false)
- `run-security` (default: false)
- `test-coverage` (default: false)
- Plus all individual job inputs

#### `pack-deploy-dev.yml`
Complete development deployment to Fly.io.

**Features:**
- Quality checks (optional)
- Fly.io deployment
- Cloudflare DNS setup
- Deployment summary

**Inputs:**
- `app-name` (required)
- `fly-org` (required)
- `domain` (optional)
- `run-quality-checks` (default: true)
- Plus standard Node.js/pnpm inputs

#### `pack-deploy-prod.yml`
Complete production deployment to Fly.io.

**Features:**
- Full quality checks with security
- Blue-green deployment
- Production-grade settings
- DNS configuration

**Inputs:**
- Same as deploy-dev plus:
- `min-machines` (default: '2')
- `memory-mb` (default: '1024')

#### `pack-deploy-railway-dev.yml`
Complete development deployment to Railway.

**Features:**
- Quality checks (optional)
- Railway deployment with auto project/service creation
- Cloudflare DNS setup
- Deployment summary

**Inputs:**
- `app-name` (required) - Creates `dev-${app-name}` project
- `service-name` (optional, defaults to app-name)
- `domain` (optional)
- `run-quality-checks` (default: true)
- `variables` (optional: JSON object for environment variables)
- Plus standard Node.js/pnpm inputs

#### `pack-deploy-railway-prod.yml`
Complete production deployment to Railway.

**Features:**
- Full quality checks with security and coverage
- Railway deployment with enhanced health checks
- Production-grade settings
- DNS configuration

**Inputs:**
- Same as railway-dev plus:
- `memory-mb` (default: '1024')
- `max-wait-minutes` (default: '15')

## 🎯 Common Use Cases

### 1. PR Quality Checks (No Noise on develop→main)

```yaml
name: PR Checks
on:
  pull_request:
    branches: [main, develop]

jobs:
  quality:
    # Skip redundant checks on develop→main PRs
    if: !(github.base_ref == 'main' && github.head_ref == 'develop')
    uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@main
    with:
      run-build: false
```

### 2. Automated Development Deployment

```yaml
name: Deploy Dev
on:
  push:
    branches: [develop]

jobs:
  deploy:
    uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-dev.yml@main
    with:
      app-name: 'dev-myapp'
      fly-org: 'nextnode'
      domain: 'myapp.com'
    secrets: inherit
```

### 3. Manual Production Deployment

```yaml
name: Deploy Production
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-prod.yml@main
    with:
      app-name: 'prod-myapp'
      fly-org: 'nextnode'
      domain: 'myapp.com'
      min-machines: '3'
      memory-mb: '2048'
    secrets: inherit
```

### 4. Scheduled Security Scans

```yaml
name: Security Scan
on:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday

jobs:
  security:
    uses: NextNodeSolutions/github-actions/.github/workflows/job-security.yml@main
    with:
      audit-level: 'moderate'
```

## 🔑 Required Secrets

Configure these secrets in your repository settings:

### Railway Deployments (Recommended)
- **`RAILWAY_API_TOKEN`**: Railway account token for deployments
- **`CLOUDFLARE_API_TOKEN`**: Cloudflare API token (optional, for custom domains)

### Fly.io Deployments (Legacy)
- **`FLY_API_TOKEN`**: Fly.io API token for deployments
- **`CLOUDFLARE_API_TOKEN`**: Cloudflare API token (if using custom domains)
- **`CLOUDFLARE_ZONE_ID`**: Cloudflare zone ID (if using custom domains)

## 🔒 Access & Security

### Public Repository Benefits
This repository is **public** for maximum accessibility and ease of use:
- ✅ **Zero configuration** required for any repository to use these workflows
- ✅ **Works immediately** without access restrictions
- ✅ **Community contribution** - others can learn from and contribute to your workflows
- ✅ **No maintenance overhead** for access permissions

### Access Requirements
- ✅ **Any repository** can use these workflows (public or private)
- ✅ **No organization restrictions** - works across different organizations
- ✅ Secrets are inherited using `secrets: inherit`
- ✅ Workflows run with appropriate permissions

## 📌 Version Pinning

For production use, pin to specific versions:

```yaml
# Use specific tag
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-prod.yml@v1.0.0

# Use commit SHA
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-prod.yml@abc123

# Use main branch (latest)
uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-prod.yml@main
```

## 🧪 Testing

This repository includes comprehensive tests:

```bash
# Run all tests locally
act push

# Test specific workflow
act -W .github/workflows/test-actions.yml
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Ensure all tests pass
4. Submit a PR with clear description

## 📄 License

MIT License - see LICENSE file for details