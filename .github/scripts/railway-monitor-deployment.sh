#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./railway-graphql-utils.sh
source "$SCRIPT_DIR/railway-graphql-utils.sh"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Monitor Railway service deployment status until completion or timeout.

OPTIONS:
  --service-id ID          Railway service ID (required)
  --environment-id ID      Environment ID (required)
  --timeout SECONDS        Maximum time to wait in seconds (default: 600)
  --interval SECONDS       Poll interval in seconds (default: 10)
  --output-format FORMAT   Output format: json|env (default: env)
  -h, --help              Show this help message

ENVIRONMENT VARIABLES:
  RAILWAY_TOKEN           Railway API token (required)

DEPLOYMENT STATUSES:
  - QUEUED: Deployment is queued
  - BUILDING: Building the service
  - DEPLOYING: Deploying the service
  - SUCCESS: Deployment completed successfully
  - FAILED: Deployment failed
  - CRASHED: Deployment crashed
  - REMOVED: Deployment was removed

EXAMPLES:
  # Monitor deployment with defaults
  $0 --service-id "abc123" --environment-id "def456"

  # Monitor with custom timeout and interval
  $0 --service-id "abc123" \\
     --environment-id "def456" \\
     --timeout 900 \\
     --interval 15

  # Get JSON output
  $0 --service-id "abc123" \\
     --environment-id "def456" \\
     --output-format json

EOF
}

get_deployment_status() {
  local service_id="$1"
  local environment_id="$2"

  local response
  response=$(query_deployment_status "$service_id" "$environment_id")

  local deployment_id status created_at

  deployment_id=$(echo "$response" | jq -r '.data.deployments.edges[0].node.id // "none"')
  status=$(echo "$response" | jq -r '.data.deployments.edges[0].node.status // "UNKNOWN"')
  created_at=$(echo "$response" | jq -r '.data.deployments.edges[0].node.createdAt // ""')

  echo "$deployment_id|$status|$created_at"
}

is_terminal_status() {
  local status="$1"

  case "$status" in
    SUCCESS|FAILED|CRASHED|REMOVED)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_success_status() {
  local status="$1"
  [[ "$status" == "SUCCESS" ]]
}

main() {
  local service_id=""
  local environment_id=""
  local timeout=600
  local interval=10
  local output_format="env"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --service-id)
        service_id="$2"
        shift 2
        ;;
      --environment-id)
        environment_id="$2"
        shift 2
        ;;
      --timeout)
        timeout="$2"
        shift 2
        ;;
      --interval)
        interval="$2"
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

  if [[ -z "$service_id" || -z "$environment_id" ]]; then
    log_error "Missing required arguments"
    usage
    exit 1
  fi

  validate_token

  log_info "Monitoring deployment for service: $service_id"
  log_info "Timeout: ${timeout}s, Poll interval: ${interval}s"

  local start_time elapsed_time
  start_time=$(date +%s)

  local deployment_id status created_at
  local previous_status=""

  while true; do
    elapsed_time=$(($(date +%s) - start_time))

    if (( elapsed_time >= timeout )); then
      log_error "Deployment monitoring timed out after ${timeout}s"
      log_error "Last known status: $previous_status"
      exit 1
    fi

    local result
    if ! result=$(get_deployment_status "$service_id" "$environment_id"); then
      log_warning "Failed to query deployment status, retrying..."
      sleep "$interval"
      continue
    fi

    IFS='|' read -r deployment_id status created_at <<< "$result"

    if [[ "$deployment_id" == "none" ]]; then
      log_info "No deployment found yet, waiting..."
      sleep "$interval"
      continue
    fi

    if [[ "$status" != "$previous_status" ]]; then
      log_info "Deployment status: $status (ID: $deployment_id)"
      previous_status="$status"
    fi

    if is_terminal_status "$status"; then
      if is_success_status "$status"; then
        log_success "Deployment completed successfully!"

        case "$output_format" in
          json)
            jq -n \
              --arg deployment_id "$deployment_id" \
              --arg status "$status" \
              --arg created_at "$created_at" \
              --arg elapsed "$elapsed_time" \
              '{
                deployment_id: $deployment_id,
                status: $status,
                created_at: $created_at,
                elapsed_seconds: ($elapsed | tonumber),
                success: true
              }'
            ;;
          env)
            echo "export DEPLOYMENT_ID='$deployment_id'"
            echo "export DEPLOYMENT_STATUS='$status'"
            echo "export DEPLOYMENT_SUCCESS='true'"
            ;;
        esac

        exit 0
      else
        log_error "Deployment ended with status: $status"

        case "$output_format" in
          json)
            jq -n \
              --arg deployment_id "$deployment_id" \
              --arg status "$status" \
              --arg created_at "$created_at" \
              --arg elapsed "$elapsed_time" \
              '{
                deployment_id: $deployment_id,
                status: $status,
                created_at: $created_at,
                elapsed_seconds: ($elapsed | tonumber),
                success: false
              }'
            ;;
          env)
            echo "export DEPLOYMENT_ID='$deployment_id'"
            echo "export DEPLOYMENT_STATUS='$status'"
            echo "export DEPLOYMENT_SUCCESS='false'"
            ;;
        esac

        exit 1
      fi
    fi

    sleep "$interval"
  done
}

main "$@"
