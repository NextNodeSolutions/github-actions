#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./railway-graphql-utils.sh
source "$SCRIPT_DIR/railway-graphql-utils.sh"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Create or update a Railway service with environment variables and custom domain.

OPTIONS:
  --project-id ID          Railway project ID (required)
  --environment-id ID      Environment ID (required)
  --service-name NAME      Service name (required)
  --service-id ID          Existing service ID (optional, creates new if not provided)
  --repo REPO              GitHub repository (owner/repo format, required for new service)
  --branch BRANCH          Git branch (required for new service)
  --domain DOMAIN          Custom domain to configure (optional)
  --variables JSON         Environment variables as JSON object (required)
  --output-format FORMAT   Output format: json|env (default: env)
  -h, --help              Show this help message

ENVIRONMENT VARIABLES:
  RAILWAY_TOKEN           Railway API token (required)

EXAMPLES:
  # Create new service with variables
  $0 --project-id "abc123" \\
     --environment-id "def456" \\
     --service-name "pr-123" \\
     --repo "nextnode/fleursdaujourdhui" \\
     --branch "feature/new-design" \\
     --domain "pr-123.dev.example.com" \\
     --variables '{"URL":"https://pr-123.dev.example.com","NODE_ENV":"production"}'

  # Update existing service variables
  $0 --project-id "abc123" \\
     --environment-id "def456" \\
     --service-name "pr-123" \\
     --service-id "ghi789" \\
     --variables '{"UPDATED_VAR":"new-value"}'

EOF
}

main() {
  local project_id=""
  local environment_id=""
  local service_name=""
  local service_id=""
  local repo=""
  local branch=""
  local domain=""
  local variables=""
  local output_format="env"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --project-id)
        project_id="$2"
        shift 2
        ;;
      --environment-id)
        environment_id="$2"
        shift 2
        ;;
      --service-name)
        service_name="$2"
        shift 2
        ;;
      --service-id)
        service_id="$2"
        shift 2
        ;;
      --repo)
        repo="$2"
        shift 2
        ;;
      --branch)
        branch="$2"
        shift 2
        ;;
      --domain)
        domain="$2"
        shift 2
        ;;
      --variables)
        variables="$2"
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

  if [[ -z "$project_id" || -z "$environment_id" || -z "$service_name" || -z "$variables" ]]; then
    log_error "Missing required arguments"
    usage
    exit 1
  fi

  validate_token

  if ! echo "$variables" | jq empty 2>/dev/null; then
    log_error "Invalid JSON format for variables"
    exit 1
  fi

  local created_service="false"
  local service_url=""

  if [[ -z "$service_id" ]]; then
    if [[ -z "$repo" || -z "$branch" ]]; then
      log_error "Repository and branch are required for creating a new service"
      exit 1
    fi

    log_info "Creating new service: $service_name"
    log_info "Repository: $repo"
    log_info "Branch: $branch"

    local response
    if ! response=$(retry_with_backoff "$MAX_RETRIES" \
      mutation_create_service "$project_id" "$environment_id" "$service_name" "$repo" "$branch"); then
      log_error "Failed to create service"
      exit 1
    fi

    service_id=$(parse_json "$response" '.data.serviceCreate.id')
    log_success "Service created with ID: $service_id"
    created_service="true"

    sleep 2
  else
    log_info "Using existing service ID: $service_id"
  fi

  log_info "Setting environment variables..."
  local variables_array
  variables_array=$(echo "$variables" | jq -c 'to_entries | map({name: .key, value: .value})')

  if ! retry_with_backoff "$MAX_RETRIES" \
    mutation_upsert_variables "$project_id" "$environment_id" "$service_id" "$variables_array"; then
    log_error "Failed to set environment variables"
    exit 1
  fi
  log_success "Environment variables configured"

  if [[ -n "$domain" ]]; then
    log_info "Configuring custom domain: $domain"

    if ! retry_with_backoff "$MAX_RETRIES" \
      mutation_service_domain_create "$service_id" "$environment_id" "$domain"; then
      log_warning "Failed to configure custom domain (may already exist)"
    else
      log_success "Custom domain configured: $domain"
      service_url="https://$domain"
    fi
  fi

  case "$output_format" in
    json)
      jq -n \
        --arg service_id "$service_id" \
        --arg service_name "$service_name" \
        --arg created "$created_service" \
        --arg url "$service_url" \
        '{
          service_id: $service_id,
          service_name: $service_name,
          created: ($created == "true"),
          url: $url
        }'
      ;;
    env)
      echo "export SERVICE_ID='$service_id'"
      echo "export SERVICE_NAME='$service_name'"
      echo "export SERVICE_CREATED='$created_service'"
      if [[ -n "$service_url" ]]; then
        echo "export SERVICE_URL='$service_url'"
      fi
      ;;
    *)
      log_error "Invalid output format: $output_format"
      exit 1
      ;;
  esac

  log_success "Service deployment configured successfully"
}

main "$@"
