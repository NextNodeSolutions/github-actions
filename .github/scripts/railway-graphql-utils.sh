#!/usr/bin/env bash

set -euo pipefail

# Railway GraphQL Utilities
# Provides reusable functions for Railway API interactions

readonly RAILWAY_API_URL="${RAILWAY_API_URL:-https://backboard.railway.app/graphql/v2}"
readonly MAX_RETRIES="${MAX_RETRIES:-3}"
readonly RETRY_DELAY="${RETRY_DELAY:-2}"

log_info() {
  echo "ℹ️  $*" >&2
}

log_success() {
  echo "✅ $*" >&2
}

log_error() {
  echo "❌ $*" >&2
}

log_warning() {
  echo "⚠️  $*" >&2
}

validate_token() {
  if [[ -z "${RAILWAY_TOKEN:-}" ]]; then
    log_error "RAILWAY_TOKEN environment variable is not set"
    return 1
  fi
}

graphql_query() {
  local query="$1"
  local variables="${2:-{}}"

  validate_token

  local response
  response=$(curl -s -X POST "$RAILWAY_API_URL" \
    -H "Authorization: Bearer $RAILWAY_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "query": $(jq -n --arg q "$query" '$q'),
  "variables": $variables
}
EOF
  )

  if [[ -z "$response" ]]; then
    log_error "Empty response from Railway API"
    return 1
  fi

  local errors
  errors=$(echo "$response" | jq -r '.errors // empty')
  if [[ -n "$errors" ]]; then
    log_error "GraphQL errors: $errors"
    return 1
  fi

  echo "$response"
}

parse_json() {
  local json="$1"
  local jq_filter="$2"

  if [[ -z "$json" ]]; then
    log_error "Empty JSON input"
    return 1
  fi

  local result
  result=$(echo "$json" | jq -r "$jq_filter")

  if [[ "$result" == "null" || -z "$result" ]]; then
    log_error "Failed to parse JSON with filter: $jq_filter"
    return 1
  fi

  echo "$result"
}

retry_with_backoff() {
  local max_attempts="$1"
  shift
  local command=("$@")

  local attempt=1
  local delay="$RETRY_DELAY"

  while (( attempt <= max_attempts )); do
    if "${command[@]}"; then
      return 0
    fi

    if (( attempt < max_attempts )); then
      log_warning "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
      sleep "$delay"
      delay=$((delay * 2))
    fi

    ((attempt++))
  done

  log_error "Command failed after $max_attempts attempts"
  return 1
}

query_projects() {
  local query='
    query {
      projects {
        edges {
          node {
            id
            name
            environments {
              edges {
                node {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }
  '

  graphql_query "$query"
}

query_project_by_name() {
  local project_name="$1"

  local response
  response=$(query_projects)

  parse_json "$response" \
    ".data.projects.edges[] | select(.node.name == \"$project_name\") | .node.id"
}

query_environment_by_name() {
  local project_id="$1"
  local env_name="$2"

  local query='
    query($projectId: String!) {
      project(id: $projectId) {
        environments {
          edges {
            node {
              id
              name
            }
          }
        }
      }
    }
  '

  local variables
  variables=$(jq -n \
    --arg projectId "$project_id" \
    '{projectId: $projectId}'
  )

  local response
  response=$(graphql_query "$query" "$variables")

  parse_json "$response" \
    ".data.project.environments.edges[] | select(.node.name == \"$env_name\") | .node.id"
}

query_services() {
  local project_id="$1"
  local environment_id="$2"

  local query='
    query($projectId: String!, $environmentId: String!) {
      project(id: $projectId) {
        services(environmentId: $environmentId) {
          edges {
            node {
              id
              name
            }
          }
        }
      }
    }
  '

  local variables
  variables=$(jq -n \
    --arg projectId "$project_id" \
    --arg environmentId "$environment_id" \
    '{projectId: $projectId, environmentId: $environmentId}'
  )

  graphql_query "$query" "$variables"
}

query_service_by_name() {
  local project_id="$1"
  local environment_id="$2"
  local service_name="$3"

  local response
  response=$(query_services "$project_id" "$environment_id")

  parse_json "$response" \
    ".data.project.services.edges[] | select(.node.name == \"$service_name\") | .node.id"
}

mutation_create_service() {
  local project_id="$1"
  local environment_id="$2"
  local service_name="$3"
  local source_repo_full_name="$4"
  local source_repo_branch="$5"

  local mutation='
    mutation($input: ServiceCreateInput!) {
      serviceCreate(input: $input) {
        id
        name
      }
    }
  '

  local variables
  variables=$(jq -n \
    --arg projectId "$project_id" \
    --arg environmentId "$environment_id" \
    --arg name "$service_name" \
    --arg repoFullName "$source_repo_full_name" \
    --arg branch "$source_repo_branch" \
    '{
      input: {
        projectId: $projectId,
        environmentId: $environmentId,
        name: $name,
        source: {
          repo: $repoFullName,
          branch: $branch
        }
      }
    }'
  )

  graphql_query "$mutation" "$variables"
}

mutation_upsert_variables() {
  local project_id="$1"
  local environment_id="$2"
  local service_id="$3"
  shift 3
  local variables_json="$@"

  local mutation='
    mutation($input: VariableCollectionUpsertInput!) {
      variableCollectionUpsert(input: $input)
    }
  '

  local variables
  variables=$(jq -n \
    --arg projectId "$project_id" \
    --arg environmentId "$environment_id" \
    --arg serviceId "$service_id" \
    --argjson vars "$variables_json" \
    '{
      input: {
        projectId: $projectId,
        environmentId: $environmentId,
        serviceId: $serviceId,
        variables: $vars
      }
    }'
  )

  graphql_query "$mutation" "$variables"
}

mutation_service_domain_create() {
  local service_id="$1"
  local environment_id="$2"
  local domain="$3"

  local mutation='
    mutation($input: ServiceDomainCreateInput!) {
      serviceDomainCreate(input: $input) {
        id
        domain
      }
    }
  '

  local variables
  variables=$(jq -n \
    --arg serviceId "$service_id" \
    --arg environmentId "$environment_id" \
    --arg domain "$domain" \
    '{
      input: {
        serviceId: $serviceId,
        environmentId: $environmentId,
        domain: $domain
      }
    }'
  )

  graphql_query "$mutation" "$variables"
}

mutation_service_delete() {
  local service_id="$1"

  local mutation='
    mutation($id: String!) {
      serviceDelete(id: $id)
    }
  '

  local variables
  variables=$(jq -n \
    --arg id "$service_id" \
    '{id: $id}'
  )

  graphql_query "$mutation" "$variables"
}

query_deployment_status() {
  local service_id="$1"
  local environment_id="$2"

  local query='
    query($serviceId: String!, $environmentId: String!) {
      deployments(
        first: 1
        input: {
          serviceId: $serviceId
          environmentId: $environmentId
        }
      ) {
        edges {
          node {
            id
            status
            createdAt
          }
        }
      }
    }
  '

  local variables
  variables=$(jq -n \
    --arg serviceId "$service_id" \
    --arg environmentId "$environment_id" \
    '{serviceId: $serviceId, environmentId: $environmentId}'
  )

  graphql_query "$query" "$variables"
}

export -f log_info log_success log_error log_warning
export -f validate_token graphql_query parse_json retry_with_backoff
export -f query_projects query_project_by_name query_environment_by_name
export -f query_services query_service_by_name
export -f mutation_create_service mutation_upsert_variables
export -f mutation_service_domain_create mutation_service_delete
export -f query_deployment_status
