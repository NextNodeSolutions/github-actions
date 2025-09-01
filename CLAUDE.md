# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **reusable GitHub Actions repository** for NextNode projects. It provides centralized CI/CD workflows and composite actions for consistent automation across all NextNode repositories.

**Key principle**: **pnpm only** - This repository exclusively uses pnpm as the package manager. No npm or yarn support.

## Architecture

### Current Repository Structure
```
github-actions/
├── .github/workflows/          # Reusable workflows (external + internal)
│   ├── quality-checks.yml     # Full quality pipeline (workflow_call)
│   ├── deploy.yml             # Railway deployment (workflow_call)
│   ├── dns.yml                # DNS Cloudflare management (workflow_call)
│   └── internal-tests.yml     # Internal tests (workflow_dispatch only)
├── actions/                    # Domain-organized atomic actions
│   ├── build/                 # 🏗️ Build & Setup domain
│   │   ├── install/           # Dependency installation
│   │   ├── build-project/     # Project building
│   │   └── smart-cache/       # Intelligent caching
│   ├── quality/               # 🔍 Code Quality domain
│   │   ├── lint/              # ESLint checks
│   │   ├── typecheck/         # TypeScript validation
│   │   └── security-audit/    # Security scanning
│   ├── deploy/                # 🚀 Railway Deployment domain
│   │   ├── railway-cli-setup/ # Railway CLI configuration
│   │   ├── railway-project-setup/ # Railway project management
│   │   ├── railway-service-setup/ # Railway service configuration
│   │   ├── railway-deploy/    # Main deployment action
│   │   ├── railway-deploy-trigger/ # Deployment triggering
│   │   ├── railway-deployment-wait/ # Deployment monitoring
│   │   ├── railway-variables/ # Environment variables
│   │   └── railway-url-generate/ # URL generation
│   ├── domain/                # 🌐 Domain Management domain
│   │   └── railway-domain-setup/ # Domain configuration
│   ├── monitoring/            # 🔍 Monitoring domain
│   │   └── check-job-results/ # Job result verification
│   ├── utilities/             # 🛠️ Generic Utilities domain
│   │   ├── log-step/          # Enhanced logging
│   │   ├── run-command/       # Command wrapper
│   │   ├── check-command/     # Command availability check
│   │   ├── set-env-vars/      # Environment management
│   │   └── should-run/        # Conditional logic
│   ├── node-setup-complete/   # ✅ Global: Complete Node.js setup (used externally)
│   ├── test/                  # ✅ Global: Test execution (used externally)
│   └── health-check/          # ✅ Global: URL health monitoring (used externally)
└── README.md                   # User documentation
```

### Design Principles

1. **Domain Organization**: Actions are grouped by functional domain for better navigation
2. **Atomic Actions**: Each action in `/actions/` does ONE thing well
3. **Global Actions Preservation**: `test/` and `health-check/` remain at root for external compatibility
4. **No Package Manager Conditionals**: pnpm is hardcoded everywhere - no switches or alternatives
5. **Workflow Isolation**: 
   - External workflows use `workflow_call` trigger only
   - Internal tests use `workflow_dispatch` to prevent recursion
6. **Maximum Reusability**: Actions can be used individually or composed
7. **DRY Principle**: No code duplication, shared logic in atomic actions
8. **Clean Logging**: All actions use GitHub groups and timing metrics

### Domain Organization Philosophy

The actions are organized into logical domains to improve maintainability and discoverability:

- **🏗️ build/**: Everything related to project setup, dependency installation, and building
- **🔍 quality/**: Code quality checks including linting, type checking, and security
- **🚀 deploy/**: Railway platform deployment and infrastructure management  
- **🌐 domain/**: Domain and DNS management (separate from deployment)
- **🔍 monitoring/**: Health checks and job result verification
- **🛠️ utilities/**: Generic helper actions used across domains
- **Root level**: Only globally-used actions that external projects depend on

## Usage Patterns

### For External Projects

External projects can call workflows in two ways:

1. **Full pipelines** (workflow packs):
```yaml
uses: nextnodesolutions/github-actions/.github/workflows/quality-checks.yml@main
uses: nextnodesolutions/github-actions/.github/workflows/deploy.yml@main
```

2. **Individual actions**:

**Global actions (root level - always accessible):**
```yaml
uses: nextnodesolutions/github-actions/actions/node-setup-complete@main
uses: nextnodesolutions/github-actions/actions/test@main
uses: nextnodesolutions/github-actions/actions/health-check@main
```

**Domain-specific actions (internal use only):**
```yaml
# Build domain
uses: nextnodesolutions/github-actions/actions/build/install@main

# Quality domain  
uses: nextnodesolutions/github-actions/actions/quality/lint@main
uses: nextnodesolutions/github-actions/actions/quality/typecheck@main

# Deploy domain
uses: nextnodesolutions/github-actions/actions/deploy/railway-deploy@main
```

### For This Repository

Internal testing uses `internal-tests.yml` with manual trigger only to avoid recursion.

## Important Notes for Development

### When Adding New Actions
1. **Choose appropriate domain**: Place in correct domain folder (`build/`, `quality/`, `deploy/`, `domain/`, `monitoring/`, `utilities/`)
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
1. Use `internal-tests.yml` for testing within this repo
2. Test with `workflow_dispatch` event
3. Never commit test workflows that trigger on push

## Common Tasks

### Adding a New Atomic Action
```bash
# Choose appropriate domain first
mkdir actions/utilities/my-new-action
touch actions/utilities/my-new-action/action.yml
# Add action logic using existing patterns
```

### Domain Selection Guide
- **build/**: Installation, building, caching (Node setup is now global)
- **quality/**: Linting, type checking, testing, security audits  
- **deploy/**: Railway deployment and infrastructure
- **domain/**: Domain and DNS management
- **monitoring/**: Health checks, job verification
- **utilities/**: Generic helpers and tools
- **Global level**: Complete setups and externally-used actions

### Testing Actions Locally
```bash
# Use act or similar tools
act workflow_dispatch -W .github/workflows/internal-tests.yml
```

### Debugging Workflow Issues
1. Check workflow syntax
2. **Verify action paths**: Use domain-based paths (e.g., `actions/build/install`, not `actions/install`)
3. **Global actions**: Only `test/` and `health-check/` are at root level
4. Ensure proper trigger configuration
5. Review logs with expanded groups

## Migration Notes

### Latest Migration: Domain Organization (2025)
This repository was reorganized by domain for better maintainability:
- **Organized**: Actions grouped into logical domains (`build/`, `quality/`, `deploy/`, etc.)
- **Preserved**: Global actions `test/` and `health-check/` at root for external compatibility
- **Separated**: Deploy vs Domain management (Railway deployment vs DNS/domain setup)
- **Updated**: All internal workflow references to use new paths

### Previous Migrations
- Removed: workflow-templates/, packs/, internal/ directories  
- Removed: Fly.io deployment support
- Removed: npm/yarn support
- Simplified: Action paths (removed unnecessary nesting)
- Unified: Deployment workflows (single file for all environments)

## Dependencies

- **pnpm**: Version 10.12.4+ required
- **Node.js**: Version 20+ recommended
- **Railway CLI**: For deployment workflows
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
4. **"Recursion detected"**: Check triggers - no push/PR triggers on this repo
5. **"Global action moved"**: Only `node-setup-complete/`, `test/` and `health-check/` remain at root level

### Debug Mode

Enable debug logging by setting repository secret:
- `ACTIONS_RUNNER_DEBUG: true`
- `ACTIONS_STEP_DEBUG: true`