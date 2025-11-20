#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./railway-graphql-utils.sh
source "$SCRIPT_DIR/railway-graphql-utils.sh"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Delete a Railway service (typically for PR preview cleanup).

OPTIONS:
  --service-id ID          Railway service ID (optional if using --service-name)
  --project-id ID          Railway project ID (required with --service-name)
  --environment-id ID      Environment ID (required with --service-name)
  --service-name NAME      Service name to lookup and delete (optional)
  --force                  Skip confirmation prompt (default in CI)
  --output-format FORMAT   Output format: json|text (default: text)
  -h, --help              Show this help message

ENVIRONMENT VARIABLES:
  RAILWAY_TOKEN           Railway API token (required)
  CI                      When set, automatically enables --force

EXAMPLES:
  # Delete by service ID
  $0 --service-id "abc123"

  # Delete by service name (auto-discovery)
  $0 --project-id "abc123" \\
     --environment-id "def456" \\
     --service-name "pr-123"

  # Delete with explicit confirmation in interactive mode
  $0 --service-id "abc123"

  # Force deletion without prompt (useful in CI)
  $0 --service-id "abc123" --force

EOF
}

confirm_deletion() {
  local service_id="$1"
  local service_name="${2:-unknown}"

  if [[ "${CI:-false}" == "true" ]] || [[ "${FORCE:-false}" == "true" ]]; then
    return 0
  fi

  log_warning "You are about to delete service:"
  log_warning "  Service ID: $service_id"
  log_warning "  Service Name: $service_name"
  echo -n "Are you sure? (yes/no): " >&2
  read -r response

  if [[ "$response" != "yes" ]]; then
    log_info "Deletion cancelled"
    exit 0
  fi
}

main() {
  local service_id=""
  local project_id=""
  local environment_id=""
  local service_name=""
  local force="${CI:-false}"
  local output_format="text"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --service-id)
        service_id="$2"
        shift 2
        ;;
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
      --force)
        force="true"
        shift
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

  validate_token

  if [[ -z "$service_id" ]]; then
    if [[ -z "$service_name" || -z "$project_id" || -z "$environment_id" ]]; then
      log_error "Either --service-id or (--service-name + --project-id + --environment-id) required"
      usage
      exit 1
    fi

    log_info "Looking up service: $service_name"
    if ! service_id=$(retry_with_backoff "$MAX_RETRIES" \
      query_service_by_name "$project_id" "$environment_id" "$service_name"); then
      log_warning "Service not found: $service_name"
      log_info "Nothing to clean up"

      case "$output_format" in
        json)
          jq -n \
            --arg service_name "$service_name" \
            '{
              deleted: false,
              reason: "Service not found",
              service_name: $service_name
            }'
          ;;
        text)
          echo "Service not found: $service_name"
          ;;
      esac

      exit 0
    fi

    log_success "Found service ID: $service_id"
  fi

  export FORCE="$force"
  confirm_deletion "$service_id" "$service_name"

  log_info "Deleting service: $service_id"

  if ! retry_with_backoff "$MAX_RETRIES" mutation_service_delete "$service_id"; then
    log_error "Failed to delete service"

    case "$output_format" in
      json)
        jq -n \
          --arg service_id "$service_id" \
          --arg service_name "$service_name" \
          '{
            deleted: false,
            reason: "API request failed",
            service_id: $service_id,
            service_name: $service_name
          }'
        ;;
      text)
        echo "Failed to delete service: $service_id"
        ;;
    esac

    exit 1
  fi

  log_success "Service deleted successfully"

  case "$output_format" in
    json)
      jq -n \
        --arg service_id "$service_id" \
        --arg service_name "$service_name" \
        '{
          deleted: true,
          service_id: $service_id,
          service_name: $service_name
        }'
      ;;
    text)
      echo "Service deleted: $service_id"
      ;;
  esac
}

main "$@"
