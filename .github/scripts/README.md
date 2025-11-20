# Railway GraphQL Scripts

Modular shell scripts for managing Railway deployments using the GraphQL API instead of CLI.

## 🎯 Purpose

These scripts solve the **canonical URL timing issue** where environment variables were set AFTER the first build started, causing incorrect URLs in meta tags.

### Migration Benefits

- ✅ **Proper Variable Timing**: Variables set BEFORE deployment triggers
- ✅ **100% Dynamic**: No hardcoded values, all PR numbers and domains generated
- ✅ **Modular**: Reusable scripts for different workflows
- ✅ **Reliable**: Built-in retry logic with exponential backoff
- ✅ **Transparent**: Detailed logging and error messages

## 📁 Script Overview

| Script                          | Purpose                                  | Usage                          |
| ------------------------------- | ---------------------------------------- | ------------------------------ |
| `railway-graphql-utils.sh`      | Core GraphQL utilities and API wrappers  | Sourced by other scripts       |
| `railway-get-ids.sh`            | Discover Project/Environment/Service IDs | ID discovery before operations |
| `railway-service-deploy.sh`     | Create/update service with variables     | Deploy PR previews             |
| `railway-monitor-deployment.sh` | Poll deployment status until completion  | Wait for successful deployment |
| `railway-cleanup.sh`            | Delete services on PR close              | Cleanup PR previews            |

## 🚀 Quick Start

### Prerequisites

- `bash` 4.0+
- `jq` for JSON parsing
- `curl` for API requests
- `RAILWAY_TOKEN` environment variable

### Installation

Copy all scripts to `.github/scripts/` in your repository:

```bash
cp railway-*.sh .github/scripts/
chmod +x .github/scripts/railway-*.sh
```

### Basic Usage

#### 1. Discover Railway IDs

```bash
eval $(.github/scripts/railway-get-ids.sh \
  --project-name "myproject" \
  --environment-name "production")

echo "Project ID: $PROJECT_ID"
echo "Environment ID: $ENVIRONMENT_ID"
```

#### 2. Deploy a Service

```bash
VARIABLES='{"URL":"https://pr-123.dev.example.com","NODE_ENV":"production"}'

eval $(.github/scripts/railway-service-deploy.sh \
  --project-id "$PROJECT_ID" \
  --environment-id "$ENVIRONMENT_ID" \
  --service-name "pr-123" \
  --repo "owner/repo" \
  --branch "feature/branch" \
  --domain "pr-123.dev.example.com" \
  --variables "$VARIABLES")

echo "Service ID: $SERVICE_ID"
```

#### 3. Monitor Deployment

```bash
.github/scripts/railway-monitor-deployment.sh \
  --service-id "$SERVICE_ID" \
  --environment-id "$ENVIRONMENT_ID" \
  --timeout 600
```

#### 4. Cleanup Service

```bash
.github/scripts/railway-cleanup.sh \
  --project-id "$PROJECT_ID" \
  --environment-id "$ENVIRONMENT_ID" \
  --service-name "pr-123" \
  --force
```

## 📚 Detailed Documentation

### railway-graphql-utils.sh

Core utilities library providing:

**Logging Functions:**

- `log_info()` - Info messages
- `log_success()` - Success messages
- `log_error()` - Error messages
- `log_warning()` - Warning messages

**GraphQL Functions:**

- `graphql_query(query, variables)` - Execute GraphQL queries
- `parse_json(json, jq_filter)` - Parse JSON responses
- `retry_with_backoff(max_attempts, command...)` - Retry with exponential backoff

**Railway Queries:**

- `query_projects()` - List all projects
- `query_project_by_name(name)` - Get project ID by name
- `query_environment_by_name(project_id, env_name)` - Get environment ID
- `query_services(project_id, environment_id)` - List services
- `query_service_by_name(project_id, environment_id, service_name)` - Get service ID
- `query_deployment_status(service_id, environment_id)` - Get deployment status

**Railway Mutations:**

- `mutation_create_service(project_id, environment_id, name, repo, branch)` - Create service
- `mutation_upsert_variables(project_id, environment_id, service_id, variables_json)` - Set variables
- `mutation_service_domain_create(service_id, environment_id, domain)` - Add custom domain
- `mutation_service_delete(service_id)` - Delete service

### railway-get-ids.sh

Dynamically discover Railway resource IDs.

**Options:**

- `--project-name NAME` - Railway project name (required)
- `--environment-name NAME` - Environment name (required)
- `--service-name NAME` - Service name (optional, checks existence)
- `--output-format FORMAT` - Output: `json` or `env` (default: `env`)

**Output (env format):**

```bash
export PROJECT_ID='...'
export ENVIRONMENT_ID='...'
export SERVICE_ID='...'  # Only if service exists
export SERVICE_EXISTS='true|false'
```

**Output (json format):**

```json
{
	"project_id": "...",
	"environment_id": "...",
	"service_id": "...",
	"service_exists": true
}
```

### railway-service-deploy.sh

Create or update a Railway service with environment variables.

**Options:**

- `--project-id ID` - Railway project ID (required)
- `--environment-id ID` - Environment ID (required)
- `--service-name NAME` - Service name (required)
- `--service-id ID` - Existing service ID (optional, creates new if omitted)
- `--repo REPO` - GitHub repo (owner/repo format, required for new service)
- `--branch BRANCH` - Git branch (required for new service)
- `--domain DOMAIN` - Custom domain (optional)
- `--variables JSON` - Environment variables as JSON object (required)
- `--output-format FORMAT` - Output: `json` or `env` (default: `env`)

**Variables JSON Format:**

```json
{
	"URL": "https://example.com",
	"NODE_ENV": "production",
	"PORT": "3000"
}
```

**Output (env format):**

```bash
export SERVICE_ID='...'
export SERVICE_NAME='...'
export SERVICE_CREATED='true|false'
export SERVICE_URL='...'  # Only if domain configured
```

### railway-monitor-deployment.sh

Monitor deployment status with polling and timeout.

**Options:**

- `--service-id ID` - Railway service ID (required)
- `--environment-id ID` - Environment ID (required)
- `--timeout SECONDS` - Maximum wait time (default: 600)
- `--interval SECONDS` - Poll interval (default: 10)
- `--output-format FORMAT` - Output: `json` or `env` (default: `env`)

**Deployment Statuses:**

- `QUEUED` - Deployment queued
- `BUILDING` - Building the service
- `DEPLOYING` - Deploying the service
- `SUCCESS` - ✅ Deployment successful (exit 0)
- `FAILED` - ❌ Deployment failed (exit 1)
- `CRASHED` - ❌ Deployment crashed (exit 1)
- `REMOVED` - ❌ Deployment removed (exit 1)

**Output (env format):**

```bash
export DEPLOYMENT_ID='...'
export DEPLOYMENT_STATUS='SUCCESS'
export DEPLOYMENT_SUCCESS='true'
```

### railway-cleanup.sh

Delete a Railway service (typically for PR cleanup).

**Options:**

- `--service-id ID` - Railway service ID (optional if using --service-name)
- `--project-id ID` - Railway project ID (required with --service-name)
- `--environment-id ID` - Environment ID (required with --service-name)
- `--service-name NAME` - Service name to lookup and delete (optional)
- `--force` - Skip confirmation (default in CI via `$CI` env var)
- `--output-format FORMAT` - Output: `json` or `text` (default: `text`)

**Behavior:**

- In CI (`CI=true`): Auto-confirms deletion
- Interactive mode: Prompts for confirmation
- Service not found: Exits successfully (nothing to clean)

## 🔧 GitHub Actions Integration

### PR Preview Workflow

See `.github/workflows/pr-preview-graphql.yml` for the complete workflow.

**Key Steps:**

1. **Quality Checks** (optional)
    - Lint, typecheck, tests

2. **Discover IDs**

    ```yaml
    - name: Discover Railway IDs
      run: |
          eval $(.github/scripts/railway-get-ids.sh \
            --project-name "$PROJECT_NAME" \
            --environment-name "$ENVIRONMENT")
    ```

3. **Deploy Service**

    ```yaml
    - name: Deploy Railway Service
      run: |
          VARIABLES='{"URL":"...","NODE_ENV":"production"}'
          eval $(.github/scripts/railway-service-deploy.sh \
            --project-id "$PROJECT_ID" \
            --environment-id "$ENVIRONMENT_ID" \
            --service-name "pr-$PR_NUMBER" \
            --repo "$GITHUB_REPOSITORY" \
            --branch "$GITHUB_HEAD_REF" \
            --domain "$CUSTOM_DOMAIN" \
            --variables "$VARIABLES")
    ```

4. **Monitor Deployment**
    ```yaml
    - name: Monitor Deployment
      run: |
          .github/scripts/railway-monitor-deployment.sh \
            --service-id "$SERVICE_ID" \
            --environment-id "$ENVIRONMENT_ID" \
            --timeout 600
    ```

### Cleanup Workflow

See `.github/workflows/pr-preview-cleanup-graphql.yml`.

```yaml
- name: Delete Railway Service
  run: |
      .github/scripts/railway-cleanup.sh \
        --project-id "$PROJECT_ID" \
        --environment-id "$ENVIRONMENT_ID" \
        --service-name "pr-$PR_NUMBER" \
        --force
```

## 🔐 Environment Variables

| Variable          | Required | Description                                                      |
| ----------------- | -------- | ---------------------------------------------------------------- |
| `RAILWAY_TOKEN`   | Yes      | Railway API token (set in GitHub secrets)                        |
| `RAILWAY_API_URL` | No       | API endpoint (default: https://backboard.railway.app/graphql/v2) |
| `MAX_RETRIES`     | No       | Max retry attempts (default: 3)                                  |
| `RETRY_DELAY`     | No       | Initial retry delay in seconds (default: 2)                      |
| `CI`              | No       | Auto-enables --force in cleanup (set by GitHub Actions)          |

## 🐛 Debugging

### Enable Debug Logging

Add `set -x` to any script for verbose output:

```bash
bash -x .github/scripts/railway-get-ids.sh --project-name "test"
```

### Common Issues

**1. "Empty response from Railway API"**

- Check `RAILWAY_TOKEN` is set and valid
- Verify network connectivity
- Check Railway API status

**2. "Failed to find project"**

- Verify project name matches exactly (case-sensitive)
- Check token has access to the project

**3. "Deployment monitoring timed out"**

- Increase `--timeout` value
- Check Railway dashboard for deployment logs
- Verify service configuration is correct

**4. "Service not found" during cleanup**

- This is NORMAL - service may have been manually deleted
- Script exits successfully (nothing to clean)

## 📊 Comparison: CLI vs GraphQL

| Feature               | Railway CLI           | GraphQL API            |
| --------------------- | --------------------- | ---------------------- |
| Variable timing       | After build starts ❌ | Before build starts ✅ |
| Requires installation | Yes                   | No (curl only)         |
| Retry logic           | Manual                | Built-in ✅            |
| Granular control      | Limited               | Full GraphQL power ✅  |
| Error handling        | Basic                 | Detailed ✅            |
| Modularity            | Monolithic            | Modular scripts ✅     |

## 🎓 Advanced Usage

### Conditional Service Creation

```bash
# Check if service exists first
eval $(.github/scripts/railway-get-ids.sh \
  --project-name "myproject" \
  --environment-name "prod" \
  --service-name "pr-123")

if [[ "$SERVICE_EXISTS" == "true" ]]; then
  echo "Updating existing service: $SERVICE_ID"
  SERVICE_ID_FLAG="--service-id $SERVICE_ID"
else
  echo "Creating new service"
  SERVICE_ID_FLAG=""
fi

# Deploy with conditional flag
eval $(.github/scripts/railway-service-deploy.sh \
  --project-id "$PROJECT_ID" \
  --environment-id "$ENVIRONMENT_ID" \
  --service-name "pr-123" \
  $SERVICE_ID_FLAG \
  --repo "owner/repo" \
  --branch "main" \
  --variables '{"URL":"https://example.com"}')
```

### Custom Retry Configuration

```bash
export MAX_RETRIES=5
export RETRY_DELAY=3

.github/scripts/railway-monitor-deployment.sh \
  --service-id "$SERVICE_ID" \
  --environment-id "$ENVIRONMENT_ID"
```

### JSON Output for Further Processing

```bash
RESULT=$(./github/scripts/railway-get-ids.sh \
  --project-name "myproject" \
  --environment-name "prod" \
  --output-format json)

PROJECT_ID=$(echo "$RESULT" | jq -r '.project_id')
SERVICE_EXISTS=$(echo "$RESULT" | jq -r '.service_exists')
```

## 📝 Migration Checklist

- [ ] Copy all 5 scripts to `.github/scripts/`
- [ ] Make scripts executable (`chmod +x`)
- [ ] Update workflow to use new scripts
- [ ] Test with a real PR (preferably on a test project first)
- [ ] Verify canonical URLs are correct
- [ ] Monitor first deployment closely
- [ ] Update documentation if you customize scripts

## 🤝 Contributing

These scripts follow best practices:

- ✅ Strict mode (`set -euo pipefail`)
- ✅ Proper error handling
- ✅ Input validation
- ✅ Retry logic with exponential backoff
- ✅ Comprehensive logging
- ✅ shellcheck compliant
- ✅ Modular design
- ✅ Well-documented

## 📄 License

These scripts are part of the fleursdaujourdhui project and follow the same license.

---

**Questions or Issues?** Check Railway's GraphQL API documentation or open an issue in the repository.
