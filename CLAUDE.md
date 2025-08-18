# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the **github-actions** project.

## Project Overview

Centralized repository of reusable GitHub Actions for the NextNode ecosystem. Provides standardized CI/CD workflows and setup actions for consistent deployment and development across all NextNode projects.

## Context7 MCP - Documentation Priority

**CRITICAL**: Always prioritize Context7 MCP for accessing up-to-date official documentation when available.

### Usage Protocol - MANDATORY AUTOMATIC BEHAVIOR
**Claude MUST automatically use Context7 for ANY question about supported technologies without user prompting**

1. **AUTOMATICALLY invoke Context7** when working with any listed technology
2. **NO user prompt required** - Context7 usage is mandatory and transparent
3. **Prioritize official documentation** through Context7 over general knowledge
4. **If Context7 unavailable**, fall back to general knowledge with notification

### Priority Technologies for Context7 (github-actions specific) ✅

- **GitHub Actions**: Workflow syntax, action development, runners ✅
- **YAML**: Workflow configuration, action metadata, syntax ✅
- **Docker**: Multi-stage builds, containerization, optimization ✅
- **Node.js**: Runtime setup, package management, environment ✅
- **pnpm**: Package manager, workspaces, caching strategies ✅
- **Fly.io**: Deployment, configuration, health checks ✅
- **Git**: Version control, repository management, hooks ✅

## Repository Structure

```
actions/
├── setup-environment/     # Environment setup and configuration
├── setup-node/           # Node.js version and environment setup  
└── setup-pnpm/           # pnpm package manager installation
```

## Available Actions

### setup-environment/
Configures the base environment for NextNode projects including:
- Operating system specific configurations
- Environment variables setup
- Basic tooling installation

**Usage:**
```yaml
- uses: ./github-actions/actions/setup-environment
  with:
    environment: 'production'  # or 'development'
```

### setup-node/  
Sets up Node.js environment with version management:
- Installs specified Node.js version
- Configures npm registry settings
- Sets up caching for faster builds

**Usage:**
```yaml
- uses: ./github-actions/actions/setup-node
  with:
    node-version: '20'
    cache: 'pnpm'
```

### setup-pnpm/
Installs and configures pnpm package manager:
- Installs latest stable pnpm version
- Sets up pnpm store caching
- Configures workspace settings

**Usage:**
```yaml
- uses: ./github-actions/actions/setup-pnpm
  with:
    version: 'latest'
```

## Common Workflow Patterns

### Standard NextNode Project Deployment
```yaml
name: Deploy to Fly.io

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: ./github-actions/actions/setup-node
        with:
          node-version: '20'
          
      - uses: ./github-actions/actions/setup-pnpm
      
      - uses: ./github-actions/actions/setup-environment
        with:
          environment: 'production'
          
      # Project specific build and deploy steps
```

### TypeScript Project CI
```yaml
name: CI

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: ./github-actions/actions/setup-node
        with:
          node-version: '20'
          
      - uses: ./github-actions/actions/setup-pnpm
      
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm type-check
      - run: pnpm test
      - run: pnpm build
```

## Development Guidelines

### Creating New Actions

1. **Action Structure**
```
actions/action-name/
├── action.yml           # Action metadata and inputs/outputs
├── README.md           # Action documentation
└── scripts/            # Supporting scripts if needed
```

2. **Action Metadata (action.yml)**
```yaml
name: 'Action Name'
description: 'Brief description of what this action does'
inputs:
  parameter-name:
    description: 'Parameter description'
    required: true
    default: 'default-value'
outputs:
  output-name:
    description: 'Output description'
runs:
  using: 'composite'
  steps:
    - name: 'Step name'
      run: |
        # Action implementation
      shell: bash
```

3. **Best Practices**
- Use semantic versioning for action releases
- Provide clear input/output documentation
- Include error handling and validation
- Test actions across different environments
- Use composite actions for reusability

### Testing Actions

1. **Local Testing**
- Test actions in isolation using `act` or similar tools
- Validate inputs and outputs thoroughly
- Test error conditions and edge cases

2. **Integration Testing**
- Test actions within complete workflows
- Verify compatibility with different OS environments
- Test with various input combinations

### Action Maintenance

- **Versioning**: Use tags for stable releases (v1, v1.0.0)
- **Dependencies**: Keep action dependencies minimal and up-to-date
- **Security**: Regularly audit and update dependencies
- **Documentation**: Maintain comprehensive README files for each action

## Fly.io Deployment Integration

All NextNode projects use Fly.io for deployment. Common deployment patterns:

### Environment Configuration
- Production deployments to primary regions
- Staging environments for testing
- Health check endpoints integration
- Environment-specific secrets management

### Build Optimization
- Multi-stage Docker builds
- Layer caching for faster builds
- Asset optimization and compression
- Bundle analysis and optimization

## Related Projects
- See [../CLAUDE.md](../CLAUDE.md) for multi-repo overview
- Main application in [../nextnode-front/](../nextnode-front/)
- Project templates in [../project-templates/](../project-templates/)
- Projects generated by [../project-generator/](../project-generator/) use these actions