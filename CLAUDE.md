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
│   ├── setup-node/           # Node.js setup with caching
│   └── setup-pnpm/           # pnpm setup and dependency installation
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
- `job-dns-cloudflare.yml` - DNS management via Cloudflare

### Workflow Packs (`pack-*.yml`)
- `pack-quality-checks.yml` - Combined QA (lint + typecheck + test + build)
- `pack-deploy-dev.yml` - Complete development deployment
- `pack-deploy-prod.yml` - Production deployment with blue-green strategy

## Key Implementation Details

### Composite Actions
All composite actions follow a consistent pattern:
- Use `actions/setup-node@v4` with caching
- Support configurable Node.js/pnpm versions
- Default to Node 22 and pnpm 10.11.0
- Include working directory support

### Workflow Parameters
All workflows accept standard parameters:
- `node-version` (default: '22')
- `pnpm-version` (default: '10.11.0')
- `working-directory` (default: '.')
- Custom command overrides for each job type

### Security Requirements
When using deployment workflows, these secrets must be configured:
- `FLY_API_TOKEN` - Required for Fly.io deployments
- `CLOUDFLARE_API_TOKEN` - Required for DNS management
- `CLOUDFLARE_ZONE_ID` - Required for DNS management

## Usage Patterns

### Referencing Workflows
```yaml
# Use latest from main branch
uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@main

# Pin to specific version (recommended for production)
uses: NextNodeSolutions/github-actions/.github/workflows/pack-quality-checks.yml@v1.0.0
```

### Common Integration
Most NextNode projects use this pattern:
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

## Testing Strategy

The repository includes comprehensive self-testing via `test-actions.yml`:
- Tests all composite actions independently
- Validates YAML syntax across all workflow files
- Creates mock projects to test workflow execution
- Runs on push to main/develop and PRs to main

This ensures all workflows are functional before being used by consuming repositories.