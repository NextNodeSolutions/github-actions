# NextNode GitHub Actions

> Reusable GitHub Actions and workflows for NextNode projects - **pnpm only**

## 📁 Repository Structure

```
github-actions/
├── .github/workflows/          # Reusable workflows (external + internal)
│   ├── quality-checks.yml     # Full quality pipeline (workflow_call)
│   ├── deploy.yml             # Railway deployment (workflow_call)
│   ├── release.yml            # NPM library release (workflow_call) 
│   ├── publish-release.yml    # Publish workflow with repository_dispatch
│   ├── version-management.yml # Automated versioning with changesets
│   └── [additional workflows] # Security, health checks, etc.
├── actions/                    # Domain-organized atomic actions
│   ├── build/                 # 🏗️ Build & Setup domain
│   ├── quality/               # 🔍 Code Quality domain
│   ├── deploy/                # 🚀 Railway Deployment domain
│   ├── release/               # 📦 NPM Release Management domain
│   ├── domain/                # 🌐 Domain Management domain
│   ├── monitoring/            # 🔍 Monitoring domain
│   ├── utilities/             # 🛠️ Generic Utilities domain
│   ├── node-setup-complete/   # ✅ Global: Complete Node.js setup
│   ├── test/                  # ✅ Global: Test execution
│   └── health-check/          # ✅ Global: URL health monitoring
```

## 🚀 Quick Start

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
    url: 'https://my-app.railway.app'
    max-attempts: 5
```

## 🔧 Version Auto-Detection

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

✅ **Single source of truth** - Versions defined in one place  
✅ **No version conflicts** - Local and CI environments always match  
✅ **Easy maintenance** - Update `package.json` and everywhere stays in sync  
✅ **Corepack compatible** - Works with modern Node.js toolchain  

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
# Railway deployment workflow
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: nextnodesolutions/github-actions/.github/workflows/deploy.yml@main
    with:
      environment: production
      app-name: my-app
    secrets:
      RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
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

## 📦 Available Actions

### Global Actions (External Use)

| Action | Description | Key Inputs |
|--------|-------------|------------|
| `node-setup-complete` | Complete Node.js and pnpm setup with caching | Auto-detects versions from package.json |
| `test` | Run tests with optional coverage | `coverage`, `coverage-threshold`, `test-script` |
| `health-check` | Check URL health status | `url`, `max-attempts`, `expected-status` |

### Domain Actions (Internal Use)

#### 🏗️ Build Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `build/install` | Install dependencies with pnpm | `frozen-lockfile`, `working-directory` |
| `build/build-project` | Build project with pnpm | `build-command`, `output-directory` |
| `build/smart-cache` | Intelligent dependency caching | `cache-key`, `restore-keys` |

#### 🔍 Quality Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `quality/lint` | Run ESLint with optional auto-fix | `fix`, `fail-on-warning` |
| `quality/typecheck` | Run TypeScript type checking | `strict`, `tsconfig-path` |
| `quality/security-audit` | Run security audit | `audit-level`, `fix` |

#### 🚀 Deploy Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `deploy/railway-deploy` | Deploy to Railway platform | `service-name`, `environment` |
| `deploy/railway-cli-setup` | Setup Railway CLI | `token`, `version` |
| `deploy/railway-variables` | Set Railway environment variables | `variables`, `service-name` |

#### 📦 Release Domain
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `release/changesets-setup` | Setup changesets for versioning | `version`, `working-directory` |
| `release/changesets-version` | Create version PR with changesets | `version-script`, `commit-message` |
| `release/changesets-publish` | Publish packages with changesets | `publish-script`, `registry-url` |
| `release/npm-provenance` | Setup NPM provenance attestation | `token`, `package-name` |

#### 🛠️ Utility Actions
| Action | Description | Key Inputs |
|--------|-------------|------------|
| `utilities/log-step` | Enhanced logging with groups | `title`, `message`, `level` |
| `utilities/set-env-vars` | Set environment variables | `variables`, `prefix` |
| `utilities/run-command` | Run shell commands | `command`, `working-directory` |
| `utilities/check-command` | Check if command exists | `command`, `fail-if-missing` |

## 🔧 Available Reusable Workflows

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

### Railway Deployment Workflow
**File:** `.github/workflows/deploy.yml`

Unified deployment workflow for Railway supporting multiple environments.

**Features:**
- Environment-based configuration
- Quality checks before deployment
- Health checks after deployment
- DNS configuration support

**Example:**
```yaml
jobs:
  deploy:
    uses: nextnodesolutions/github-actions/.github/workflows/deploy.yml@main
    with:
      environment: production
      app-name: nextnode-app
      memory-mb: '1024'
      run-quality-checks: true
      test-coverage: true
    secrets:
      RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

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

## ⚙️ Configuration

### Default Values

Default values are defined directly in each action's `action.yml` file:

- **Node.js version**: `20`
- **pnpm version**: `10.12.4`
- **Audit level**: `high`
- **Working directory**: `.`
- **Railway memory**: `512MB` (staging), `1024MB` (production)
- **Timeouts**: 30s health checks, 15min deploys

### Environment-Based Settings

The deployment workflow automatically adjusts settings based on environment:

| Setting | Development | Production |
|---------|------------|------------|
| Memory | 512MB | 1024MB |
| Build Command | `build:dev` | `build` |
| Coverage Threshold | 60% | 80% |
| Fail on Warning | No | Yes |

## 🧪 Testing

Internal testing is handled by the repository's own workflows.

To test workflows locally:

```bash
# Test using act (GitHub Actions local runner)
act workflow_dispatch -W .github/workflows/quality-checks.yml

# Run specific workflow
gh workflow run quality-checks.yml
```

## 📋 Requirements

- **Node.js:** v20+ recommended
- **pnpm:** v10.12.4+ required (npm and yarn are not supported)
- **GitHub Actions:** All workflows use GitHub-hosted runners

## 🔒 Security

- All workflows use `pnpm audit` for security scanning
- Production deployments require passing security checks
- Automated dependency updates via Dependabot
- Secrets are never logged or exposed

## 🤝 Contributing

1. Create atomic actions for single responsibilities
2. Use pnpm exclusively (no npm/yarn support)
3. Add comprehensive logging with GitHub Actions groups
4. Include timing information for performance tracking
5. Write clear documentation with examples
6. Test internally before external use

## 📝 Migration Guide

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

## 📚 Best Practices

1. **Use Reusable Workflows:** Prefer complete workflows for common patterns
2. **Domain Organization:** Use domain-specific actions when building custom workflows
3. **Global Actions:** Use root-level actions for external projects
4. **Enable Caching:** Always enabled in `node-setup-complete` action
5. **Set Appropriate Timeouts:** Prevent hung workflows
6. **Use Groups for Logging:** All actions include grouped logging
7. **Fail Fast:** Exit early on errors
8. **Security First:** Use provenance attestation for NPM packages
9. **Automated Versioning:** Use changesets for semantic releases

## 🐛 Troubleshooting

### Common Issues

**Issue:** Dependencies not installing
- **Solution:** Ensure `pnpm-lock.yaml` exists and is committed

**Issue:** Type check failing
- **Solution:** Verify `tsconfig.json` has `strict: true`

**Issue:** Coverage threshold not met
- **Solution:** Adjust threshold or improve test coverage

**Issue:** Deployment failing
- **Solution:** Check Railway API token and project configuration

## 📄 License

MIT © NextNode Solutions

## 🔗 Links

- [NextNode](https://nextnode.dev)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [pnpm Documentation](https://pnpm.io)