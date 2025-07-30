# NextNode GitHub Actions

Centralized GitHub Actions for NextNode projects. This repository provides reusable workflows and actions to ensure consistency across all NextNode projects.

## 🎯 Design Principles

- **Zero Logic in Templates**: Project templates only import actions, no logic
- **Modular Design**: Import individual jobs or complete workflow packs
- **Branch-aware**: Smart behavior to reduce noise in PRs
- **Fully Parameterized**: Extensive configuration options for flexibility

## 📁 Repository Structure

```
github-actions/
├── actions/              # Reusable composite actions
│   ├── setup-node/      # Node.js setup with caching
│   ├── setup-pnpm/      # pnpm setup and dependency installation
│   └── setup-environment/ # Complete environment setup
├── .github/workflows/
│   ├── jobs/            # Individual job workflows
│   │   ├── lint.yml     # Linting job
│   │   ├── typecheck.yml # Type checking job
│   │   ├── test.yml     # Testing job
│   │   ├── build.yml    # Build job
│   │   ├── security.yml # Security scanning job
│   │   ├── deploy-fly.yml # Fly.io deployment
│   │   └── dns-cloudflare.yml # Cloudflare DNS management
│   └── packs/           # Workflow packs (combinations)
│       ├── quality-checks.yml # Lint + Type + Test + Build
│       ├── deploy-dev.yml     # Full dev deployment
│       └── deploy-prod.yml    # Full prod deployment
```

## ⚙️ Repository Setup (Required)

**IMPORTANT**: Before using these workflows, you must configure repository access:

1. **Navigate to Repository Settings**:
   - Go to https://github.com/NextNodeSolutions/github-actions/settings/actions
   - Click on **Actions** → **General**

2. **Configure Access**:
   - Scroll to the **"Access"** section at the bottom
   - Select **"Accessible from repositories in the 'NextNodeSolutions' organization"**
   - Click **Save**

3. **Repository Visibility**:
   - This repository is set to **Private** for organization security
   - Only NextNodeSolutions organization members can access workflows
   - No need to publish actions publicly

## 🚀 Quick Start

### Using Individual Jobs

```yaml
name: Tests
on:
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    uses: NextNodeSolutions/github-actions/.github/workflows/jobs/lint.yml@main
    with:
      node-version: '22'
      pnpm-version: '10.11.0'
      
  test:
    uses: NextNodeSolutions/github-actions/.github/workflows/jobs/test.yml@main
    with:
      coverage: true
```

### Using Workflow Packs

```yaml
name: CI/CD
on:
  push:
    branches: [develop]

jobs:
  deploy:
    uses: NextNodeSolutions/github-actions/.github/workflows/packs/deploy-dev.yml@main
    with:
      app-name: 'dev-myapp'
      fly-org: 'nextnode'
      domain: 'myapp.com'
    secrets: inherit
```

## 📋 Workflow Reference

### Individual Jobs

#### `workflows/jobs/lint.yml`
Runs linting checks on your codebase.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `command` (default: 'pnpm lint')

#### `workflows/jobs/typecheck.yml`
Runs TypeScript type checking.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `command` (default: 'pnpm type-check')

#### `workflows/jobs/test.yml`
Runs tests with optional coverage.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `coverage` (default: false)
- `command` (default: automatic based on coverage)

#### `workflows/jobs/build.yml`
Builds the project with optional artifact upload.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `command` (default: 'pnpm build')
- `upload-artifact` (default: false)
- `artifact-name` (default: 'build-output')
- `artifact-path` (default: 'dist')

#### `workflows/jobs/security.yml`
Runs security audits and Docker scans.

**Inputs:**
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- `audit-level` (default: 'high')
- `docker-scan` (default: true)

#### `workflows/jobs/deploy-fly.yml`
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

#### `workflows/jobs/dns-cloudflare.yml`
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

#### `workflows/packs/quality-checks.yml`
Combined quality checks workflow.

**Inputs:**
- `run-lint` (default: true)
- `run-typecheck` (default: true)
- `run-test` (default: true)
- `run-build` (default: false)
- `run-security` (default: false)
- `test-coverage` (default: false)
- Plus all individual job inputs

#### `workflows/packs/deploy-dev.yml`
Complete development deployment.

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

#### `workflows/packs/deploy-prod.yml`
Complete production deployment.

**Features:**
- Full quality checks with security
- Blue-green deployment
- Production-grade settings
- DNS configuration

**Inputs:**
- Same as deploy-dev plus:
- `min-machines` (default: '2')
- `memory-mb` (default: '1024')

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
    uses: NextNodeSolutions/github-actions/.github/workflows/packs/quality-checks.yml@main
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
    uses: NextNodeSolutions/github-actions/.github/workflows/packs/deploy-dev.yml@main
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
    uses: NextNodeSolutions/github-actions/.github/workflows/packs/deploy-prod.yml@main
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
    uses: NextNodeSolutions/github-actions/.github/workflows/jobs/security.yml@main
    with:
      audit-level: 'moderate'
```

## 🔑 Required Secrets

Configure these secrets in your repository settings:

- **`FLY_API_TOKEN`**: Fly.io API token for deployments
- **`CLOUDFLARE_API_TOKEN`**: Cloudflare API token (if using custom domains)
- **`CLOUDFLARE_ZONE_ID`**: Cloudflare zone ID (if using custom domains)

## 🔒 Access & Security

### Organization-Level Sharing
This repository uses GitHub's **private repository workflow sharing** feature:
- ✅ Workflows are shared only within NextNodeSolutions organization
- ✅ No public access or publishing required
- ✅ Secure by default with organization boundaries
- ✅ Available since December 2022 (GitHub Actions GA feature)

### Access Requirements
- Repository must be accessible from organization repositories
- Calling repositories must be in the same organization
- Secrets are inherited using `secrets: inherit`
- Workflows run with appropriate permissions

## 📌 Version Pinning

For production use, pin to specific versions:

```yaml
# Use specific tag
uses: NextNodeSolutions/github-actions/.github/workflows/packs/deploy-prod.yml@v1.0.0

# Use commit SHA
uses: NextNodeSolutions/github-actions/.github/workflows/packs/deploy-prod.yml@abc123

# Use main branch (latest)
uses: NextNodeSolutions/github-actions/.github/workflows/packs/deploy-prod.yml@main
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