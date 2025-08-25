# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **reusable GitHub Actions repository** for NextNode projects. It provides centralized CI/CD workflows and composite actions for consistent automation across all NextNode repositories.

## Architecture

### Repository Structure
```
github-actions/
├── actions/                    # Composite actions (building blocks)
│   ├── setup-environment/     # Complete environment setup
│   ├── setup-railway/         # Railway CLI setup and authentication
│   ├── composite-pipeline/    # All-in-one pipeline with setup + quality
│   └── quality-pipeline/      # Optimized quality checks
├── config/                     # Configuration defaults
│   └── defaults.yml
├── workflow-templates/         # Template workflows
│   └── library-ci.yml
└── .github/workflows/         # Reusable workflows
    ├── job-*.yml             # Individual job workflows
    └── pack-*.yml            # Workflow packs (combined jobs)
```

### Design Principles
- **Zero Logic in Templates**: Project templates only import actions, no logic
- **Modular Design**: Import individual jobs or complete workflow packs
- **Branch-aware**: Smart behavior to reduce noise in PRs
- **Fully Parameterized**: Extensive configuration options for flexibility

## Development Commands

### Testing Workflows Locally
```bash
# Test all workflows
act push

# Test specific workflow
act -W .github/workflows/test-actions.yml

# Test with specific runner
act -P ubuntu-latest=nektos/act-environments-ubuntu:18.04
```

### Validation
```bash
# Validate YAML syntax
find . -name "*.yml" -o -name "*.yaml" | while read file; do
  python3 -c "import yaml; yaml.safe_load(open('$file'))"
done
```

## Workflow Categories

### Individual Jobs (`job-*.yml`)
- `job-lint.yml` - Linting checks (default: `pnpm lint`)
- `job-typecheck.yml` - TypeScript checking (default: `pnpm type-check`)
- `job-test.yml` - Testing with optional coverage
- `job-build.yml` - Build with optional artifact upload
- `job-security.yml` - Security audits and Docker scans
- `job-deploy-fly.yml` - Fly.io deployment with health checks
- `job-deploy-railway.yml` - Railway deployment with health checks
- `job-dns-cloudflare.yml` - DNS management via Cloudflare

### Workflow Packs (`pack-*.yml`)
- `pack-quality-checks.yml` - Combined QA (lint + typecheck + test + build)
- `pack-deploy-dev.yml` - Complete development deployment (Fly.io)
- `pack-deploy-prod.yml` - Production deployment with blue-green strategy (Fly.io)
- `pack-deploy-railway-dev.yml` - Complete development deployment (Railway)
- `pack-deploy-railway-prod.yml` - Production deployment with approval (Railway)

## Key Implementation Details

### Composite Actions

#### `setup-environment/`
Basic environment setup with Node.js, pnpm, and dependency installation:
- Configurable Node.js/pnpm versions (default: Node 20, pnpm 10.11.0)
- Optional dependency installation with frozen lockfile
- Working directory support

#### `setup-railway/`
Railway CLI setup and authentication:
- Installs Railway CLI via npm (`@railway/cli`)
- Authenticates using RAILWAY_TOKEN
- Optional project and service linking
- Environment configuration and validation

#### `composite-pipeline/`
All-in-one pipeline combining environment setup and quality checks:
- JSON array of commands to run (e.g., `["lint", "type-check", "test", "build"]`)
- Built-in security audit with configurable severity levels
- Single action for complete CI pipeline

#### `quality-pipeline/`
Optimized quality checks with parallel execution support:
- Core checks: lint and type-check (always run)
- Optional: tests and build (can be skipped)
- Non-blocking security audit with warnings
- Grouped output for better readability

### Workflow Parameters
All workflows accept standard parameters:
- `node-version` (default: '20')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- Custom command overrides for each job type

#### Additional Parameters for Composite Actions:
- `composite-pipeline`: `commands` (JSON array), `audit-level`, `skip-audit`
- `quality-pipeline`: `skip-tests`, `skip-build`, `skip-audit`, `audit-level`

### Security Requirements
When using deployment workflows, these secrets must be configured:

#### For Fly.io Deployments:
- `FLY_API_TOKEN` - Required for Fly.io deployments
- `CLOUDFLARE_API_TOKEN` - Required for DNS management
- `CLOUDFLARE_ZONE_ID` - Required for DNS management

#### For Railway Deployments:
- `RAILWAY_TOKEN` - Required for Railway deployments
- `CLOUDFLARE_API_TOKEN` - Optional, for DNS management
- `CLOUDFLARE_ZONE_ID` - Optional, can be auto-detected from domain

## Usage Patterns

### Referencing Workflows
```yaml
# Use latest from main branch
uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@main

# Pin to specific version (recommended for production)
uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@v1.0.0
```

### Common Integration Patterns

#### Quality Checks Only
```yaml
jobs:
  quality:
    uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@main
    with:
      run-lint: true
      run-typecheck: true
      run-test: true
      test-coverage: true
```

#### Fly.io Deployment
```yaml
jobs:
  deploy-dev:
    uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-dev.yml@main
    with:
      app-name: my-app-dev
      fly-org: nextnode
      domain: example.com
    secrets:
      FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

#### Railway Deployment
```yaml
jobs:
  deploy-dev:
    uses: NextNodeSolutions/github-actions/.github/workflows/pack-deploy-railway-dev.yml@main
    with:
      project-id: ${{ vars.RAILWAY_PROJECT_ID }}
      service-name: my-service-dev
      railway-environment: development
      configure-dns: false
    secrets:
      RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

## Testing Strategy

The repository includes comprehensive self-testing via `test-actions.yml`:
- Tests all composite actions independently
- Validates YAML syntax across all workflow files
- Creates mock projects to test workflow execution
- Runs on push to main/develop and PRs to main

This ensures all workflows are functional before being used by consuming repositories.

## Migration from Fly.io to Railway

### Key Benefits of Railway
- **Cost Reduction**: 60-70% less expensive than Fly.io for multiple small applications
- **Predictable Pricing**: Fixed monthly fee ($5) plus usage, no surprise bills
- **Auto-scaling**: Scales to zero automatically, reducing idle costs
- **No Build Limits**: Unlimited builds and deployments (vs Cloudflare Pages limitations)
- **Simplified SSL**: Automatic SSL certificate management, no manual configuration

### Key Differences
- **SSL Certificates**: Railway handles SSL automatically, no manual certificate configuration needed
- **DNS Setup**: Simple CNAME pointing to Railway domain instead of IP addresses
- **Health Checks**: Railway has built-in health checks, less configuration required
- **Deployment**: Single `railway up` command vs complex Fly.io machine management

### Migration Steps
1. **Update secrets**: Replace `FLY_API_TOKEN` with `RAILWAY_TOKEN` in repository secrets
2. **Replace workflows**:
   - `pack-deploy-dev.yml` → `pack-deploy-railway-dev.yml`
   - `pack-deploy-prod.yml` → `pack-deploy-railway-prod.yml`
3. **Create Railway services**: Set up projects and services in Railway dashboard
4. **Configure environments**: Set Railway environment variables and service configuration
5. **Update DNS**: Switch from A/AAAA records to CNAME records (if using custom domains)
6. **Test thoroughly**: Deploy to development first, validate all functionality
7. **Gradual migration**: Keep Fly.io running for 48h during transition

### Railway-Specific Configuration

#### Environment Variables Setup
```bash
# In Railway project settings
APP_ENV=DEV|PROD
NODE_ENV=production
RAILWAY_ENVIRONMENT=development|production
```

#### Custom Build/Start Commands
Railway workflows support custom commands:
```yaml
- uses: ./.github/workflows/pack-deploy-railway-dev.yml@main
  with:
    service-name: my-app
    custom-build-command: "pnpm build"
    custom-start-command: "pnpm start"
```

### Cost Comparison Example
**Current Fly.io setup (3 apps)**: ~30€/month
**Railway equivalent**: ~10-15€/month (5€ base + usage)
**Monthly savings**: ~15-20€ (60-70% reduction)