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
│   ├── deploy-railway.yml     # Railway deployment (workflow_call)
│   └── internal-tests.yml     # Internal tests (workflow_dispatch only)
├── actions/                    # Atomic reusable actions
│   ├── setup-node-pnpm/       # Node.js and pnpm setup
│   ├── install/               # Dependency installation
│   ├── lint/                  # ESLint checks
│   ├── typecheck/             # TypeScript validation
│   ├── test/                  # Test execution
│   ├── build/                 # Project building
│   ├── security-audit/        # Security scanning
│   ├── health-check/          # URL health monitoring
│   ├── log-step/              # Enhanced logging
│   ├── set-env-vars/          # Environment management
│   ├── run-command/           # Command wrapper
│   └── check-command/         # Command availability check
└── README.md                   # User documentation
```

### Design Principles

1. **Atomic Actions**: Each action in `/actions/` does ONE thing well
2. **No Package Manager Conditionals**: pnpm is hardcoded everywhere - no switches or alternatives
3. **Workflow Isolation**: 
   - External workflows use `workflow_call` trigger only
   - Internal tests use `workflow_dispatch` to prevent recursion
4. **Maximum Reusability**: Actions can be used individually or composed
5. **DRY Principle**: No code duplication, shared logic in atomic actions
6. **Clean Logging**: All actions use GitHub groups and timing metrics

## Usage Patterns

### For External Projects

External projects can call workflows in two ways:

1. **Full pipelines** (workflow packs):
```yaml
uses: nextnodesolutions/github-actions/.github/workflows/quality-checks.yml@main
uses: nextnodesolutions/github-actions/.github/workflows/deploy-railway.yml@main
```

2. **Individual actions**:
```yaml
uses: nextnodesolutions/github-actions/actions/lint@main
uses: nextnodesolutions/github-actions/actions/test@main
```

### For This Repository

Internal testing uses `internal-tests.yml` with manual trigger only to avoid recursion.

## Important Notes for Development

### When Adding New Actions
1. Create a new folder in `/actions/` with descriptive name
2. Add `action.yml` (not `action.yaml`)
3. Use inputs with sensible defaults
4. Add logging with `::group::` and `::endgroup::`
5. Include timing information
6. Document inputs/outputs clearly

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
mkdir actions/my-new-action
touch actions/my-new-action/action.yml
# Add action logic using existing patterns
```

### Testing Actions Locally
```bash
# Use act or similar tools
act workflow_dispatch -W .github/workflows/internal-tests.yml
```

### Debugging Workflow Issues
1. Check workflow syntax
2. Verify action paths (remember: no `/atomic/` subdirectory)
3. Ensure proper trigger configuration
4. Review logs with expanded groups

## Migration Notes

This repository was refactored from a complex structure to a simpler, more maintainable one:
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

1. **"Action not found"**: Check path - should be `actions/name`, not `actions/atomic/name`
2. **"Workflow not accessible"**: Ensure using `workflow_call` trigger
3. **"pnpm not found"**: Always use `setup-node-pnpm` action first
4. **"Recursion detected"**: Check triggers - no push/PR triggers on this repo

### Debug Mode

Enable debug logging by setting repository secret:
- `ACTIONS_RUNNER_DEBUG: true`
- `ACTIONS_STEP_DEBUG: true`