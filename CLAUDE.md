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
- `job-dns-cloudflare.yml` - DNS management via Cloudflare

### Workflow Packs (`pack-*.yml`)
- `pack-quality-checks.yml` - Combined QA (lint + typecheck + test + build)
- `pack-deploy-dev.yml` - Complete development deployment
- `pack-deploy-prod.yml` - Production deployment with blue-green strategy

## Key Implementation Details

### Composite Actions

#### `setup-environment/`
Basic environment setup with Node.js, pnpm, and dependency installation:
- Configurable Node.js/pnpm versions (default: Node 20, pnpm 10.11.0)
- Optional dependency installation with frozen lockfile
- Working directory support

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