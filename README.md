# NextNode GitHub Actions

> Reusable GitHub Actions and workflows for NextNode projects - **pnpm only**

## 📁 Repository Structure

```
github-actions/
├── actions/           # Atomic reusable actions (external use)
│   └── atomic/       # Single-purpose atomic actions
├── packs/            # Reusable workflow combinations (external use)
├── internal/         # Internal testing workflows (not accessible externally)
└── config/           # Shared configuration files
```

## 🚀 Quick Start

### Using Atomic Actions

Atomic actions are small, focused, reusable components that perform a single task.

```yaml
# In your workflow file
- name: Setup Node.js and pnpm
  uses: nextnodesolutions/github-actions/actions/atomic/setup-node-pnpm@main
  with:
    node-version: '20'
    pnpm-version: '10.12.4'
    
- name: Install Dependencies
  uses: nextnodesolutions/github-actions/actions/atomic/install@main
  with:
    frozen-lockfile: true
    
- name: Run Tests
  uses: nextnodesolutions/github-actions/actions/atomic/test@main
  with:
    coverage: true
    coverage-threshold: '80'
```

### Using Workflow Packs

Workflow packs combine multiple atomic actions into complete workflows.

```yaml
# Quality checks workflow
name: CI

on: [push, pull_request]

jobs:
  quality:
    uses: nextnodesolutions/github-actions/packs/quality-checks.yml@main
    with:
      node-version: '20'
      test-coverage: true
      run-security: true
```

```yaml
# Deployment workflow
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: nextnodesolutions/github-actions/packs/deploy-railway.yml@main
    with:
      environment: production
      app-name: my-app
    secrets:
      RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

## 📦 Available Atomic Actions

### Core Actions

| Action | Description | Key Inputs |
|--------|-------------|------------|
| `setup-node-pnpm` | Setup Node.js and pnpm with caching | `node-version`, `pnpm-version` |
| `install` | Install dependencies with pnpm | `frozen-lockfile`, `working-directory` |
| `lint` | Run ESLint with optional auto-fix | `fix`, `fail-on-warning` |
| `typecheck` | Run TypeScript type checking | `strict`, `tsconfig-path` |
| `test` | Run tests with optional coverage | `coverage`, `coverage-threshold` |
| `build` | Build project with pnpm | `build-command`, `output-directory` |
| `security-audit` | Run security audit | `audit-level`, `fix` |

### Utility Actions

| Action | Description | Key Inputs |
|--------|-------------|------------|
| `health-check` | Check URL health status | `url`, `max-attempts`, `expected-status` |
| `log-step` | Enhanced logging with groups | `title`, `message`, `level` |
| `set-env-vars` | Set environment variables | `variables`, `prefix` |
| `run-command` | Run shell commands | `command`, `working-directory` |
| `check-command` | Check if command exists | `command`, `fail-if-missing` |

## 🔧 Available Workflow Packs

### Quality Checks Pack
**File:** `packs/quality-checks.yml`

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
    uses: nextnodesolutions/github-actions/packs/quality-checks.yml@main
    with:
      run-lint: true
      run-typecheck: true
      run-tests: true
      run-build: true
      run-security: false
      test-coverage: true
      coverage-threshold: '80'
```

### Railway Deployment Pack
**File:** `packs/deploy-railway.yml`

Unified deployment workflow for Railway supporting both development and production environments.

**Features:**
- Environment-based configuration
- Quality checks before deployment
- Health checks after deployment
- DNS configuration support

**Example:**
```yaml
jobs:
  deploy:
    uses: nextnodesolutions/github-actions/packs/deploy-railway.yml@main
    with:
      environment: production
      app-name: nextnode-app
      memory-mb: '1024'
      run-quality-checks: true
      test-coverage: true
    secrets:
      RAILWAY_API_TOKEN: ${{ secrets.RAILWAY_API_TOKEN }}
```

## ⚙️ Configuration

### Default Values

Default configuration is stored in `config/defaults.yml`:

```yaml
node:
  version: '20'
  
pnpm:
  version: '10.12.4'
  
audit:
  level: 'high'
  
railway:
  memory_mb: '512'
  memory_mb_prod: '1024'
```

### Environment-Based Settings

The deployment workflow automatically adjusts settings based on environment:

| Setting | Development | Production |
|---------|------------|------------|
| Memory | 512MB | 1024MB |
| Build Command | `build:dev` | `build` |
| Coverage Threshold | 60% | 80% |
| Fail on Warning | No | Yes |

## 🧪 Testing

Internal testing workflows are located in the `internal/` directory and are not accessible from external repositories.

To test the actions locally:

```bash
# Run internal tests (only from this repository)
gh workflow run internal/test-workflows.yml
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

Replace individual job workflows with atomic actions:

```yaml
# Old
- uses: nextnodesolutions/github-actions/.github/workflows/job-lint.yml@main

# New
- uses: nextnodesolutions/github-actions/actions/atomic/lint@main
```

## 📚 Best Practices

1. **Use Atomic Actions:** Build workflows from small, reusable pieces
2. **Enable Caching:** Always use cache for dependencies
3. **Set Appropriate Timeouts:** Prevent hung workflows
4. **Use Groups for Logging:** Improve readability with `::group::`
5. **Fail Fast:** Exit early on errors
6. **Document Inputs:** Provide clear descriptions for all inputs

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