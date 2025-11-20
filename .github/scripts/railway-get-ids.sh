#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./railway-graphql-utils.sh
source "$SCRIPT_DIR/railway-graphql-utils.sh"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Dynamically discover Railway Project, Environment, and Service IDs.

OPTIONS:
  --project-name NAME       Railway project name (required)
  --environment-name NAME   Environment name (required)
  --service-name NAME       Service name (optional, for checking existence)
  --output-format FORMAT    Output format: json|env (default: env)
  -h, --help               Show this help message

ENVIRONMENT VARIABLES:
  RAILWAY_TOKEN            Railway API token (required)

EXAMPLES:
  # Get project and environment IDs as env variables
  $0 --project-name "fleursdaujourdhui" --environment-name "production"

  # Check if service exists and get all IDs as JSON
  $0 --project-name "fleursdaujourdhui" \\
     --environment-name "production" \\
     --service-name "pr-123" \\
     --output-format json

  # Use in workflow with eval
  eval \$($0 --project-name "myproject" --environment-name "prod")
  echo "Project ID: \$PROJECT_ID"

EOF
}

main() {
  local project_name=""
  local environment_name=""
  local service_name=""
  local output_format="env"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --project-name)
        project_name="$2"
        shift 2
        ;;
      --environment-name)
        environment_name="$2"
        shift 2
        ;;
      --service-name)
        service_name="$2"
        shift 2
        ;;
      --output-format)
        output_format="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$project_name" || -z "$environment_name" ]]; then
    log_error "Missing required arguments"
    usage
    exit 1
  fi

  validate_token

  log_info "Discovering Railway IDs..."
  log_info "Project: $project_name"
  log_info "Environment: $environment_name"
  if [[ -n "$service_name" ]]; then
    log_info "Service: $service_name"
  fi

  local project_id
  log_info "Querying project ID..."
  if ! project_id=$(retry_with_backoff "$MAX_RETRIES" query_project_by_name "$project_name"); then
    log_error "Failed to find project: $project_name"
    exit 1
  fi
  log_success "Project ID: $project_id"

  local environment_id
  log_info "Querying environment ID..."
  if ! environment_id=$(retry_with_backoff "$MAX_RETRIES" query_environment_by_name "$project_id" "$environment_name"); then
    log_error "Failed to find environment: $environment_name"
    exit 1
  fi
  log_success "Environment ID: $environment_id"

  local service_id=""
  local service_exists="false"
  if [[ -n "$service_name" ]]; then
    log_info "Querying service ID..."
    if service_id=$(retry_with_backoff "$MAX_RETRIES" query_service_by_name "$project_id" "$environment_id" "$service_name"); then
      log_success "Service ID: $service_id"
      service_exists="true"
    else
      log_warning "Service not found: $service_name"
      service_exists="false"
    fi
  fi

  case "$output_format" in
    json)
      jq -n \
        --arg project_id "$project_id" \
        --arg environment_id "$environment_id" \
        --arg service_id "$service_id" \
        --arg service_exists "$service_exists" \
        '{
          project_id: $project_id,
          environment_id: $environment_id,
          service_id: $service_id,
          service_exists: ($service_exists == "true")
        }'
      ;;
    env)
      echo "export PROJECT_ID='$project_id'"
      echo "export ENVIRONMENT_ID='$environment_id'"
      if [[ -n "$service_id" ]]; then
        echo "export SERVICE_ID='$service_id'"
      fi
      echo "export SERVICE_EXISTS='$service_exists'"
      ;;
    *)
      log_error "Invalid output format: $output_format"
      exit 1
      ;;
  esac

  log_success "ID discovery completed successfully"
}

main "$@"
