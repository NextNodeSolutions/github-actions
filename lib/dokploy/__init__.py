"""Shared Python utilities for Dokploy GitHub Actions.

This library provides reusable functions for:
- Configuration loading and merging
- Domain computation
- Port detection
- GitHub Actions output handling
- Dokploy API client with consistent error handling
- Constants and enums for Dokploy operations
"""

from .client import (
    DokployAuthError,
    DokployClient,
    DokployError,
    DokployNotFoundError,
)
from .config import (
    deep_merge,
    get_environment_config,
    get_project_name,
    load_merged_config,
    load_toml,
)
from .constants import (
    # Enums
    BuildType,
    CertificateType,
    ComposeType,
    Environment,
    SourceType,
    # API
    Endpoints,
    # Infrastructure
    DEFAULT_APP_PORT,
    DEFAULT_SSH_PORT,
    DEFAULT_SSH_USER,
    DEV_SERVER,
    PROD_SERVER,
    REGISTRY_HOST,
    REGISTRY_INTERNAL_HOST,
    REGISTRY_PORT,
    TRAEFIK_SERVER,
    # Files
    APP_PORT_VAR,
    DEFAULT_COMPOSE_FILE,
    DEFAULT_CONFIG_FILE,
    DEFAULT_DOCKERFILE,
    DEFAULT_ENV_FILE,
    GITHUB_OUTPUT_VAR,
    GITHUB_REPOSITORY_VAR,
    # Domains
    DEV_DOMAIN_PREFIX,
    PREVIEW_DOMAIN_PREFIX,
    URL_SCHEME_HTTPS,
    # Timeouts
    ADMIN_SETUP_TIMEOUT,
    DEFAULT_MAX_ATTEMPTS,
    DEFAULT_RETRY_INTERVAL,
    DEFAULT_TIMEOUT,
    DEPLOY_TIMEOUT,
    DNS_TIMEOUT,
    TAILSCALE_TOKEN_TIMEOUT,
    TAILSCALE_WAIT_TIMEOUT,
    VPS_PROVISION_TIMEOUT,
    # Health check
    DEFAULT_HEALTH_INTERVAL,
    DEFAULT_HEALTH_PATH,
    DEFAULT_HEALTH_RETRIES,
    DEFAULT_HEALTH_START_PERIOD,
    DEFAULT_HEALTH_TIMEOUT,
    HEALTH_SUCCESS_CODES,
    # Resources
    DEFAULT_CPU,
    DEFAULT_CPU_LIMIT,
    DEFAULT_MEMORY,
    DEFAULT_MEMORY_LIMIT,
    DEFAULT_REPLICAS,
    DEV_CPU,
    DEV_CPU_LIMIT,
    DEV_MEMORY,
    DEV_MEMORY_LIMIT,
    # Sablier
    SABLIER_DEFAULT_THEME,
    SABLIER_IDLE_TIMEOUT,
    SABLIER_SESSION_DURATION,
    SABLIER_STARTUP_TIMEOUT,
    # HTTP
    CONTENT_TYPE_JSON,
    HEADER_API_KEY,
    HEADER_AUTHORIZATION,
    HEADER_CONTENT_TYPE,
    HTTP_BAD_REQUEST,
    HTTP_CREATED,
    HTTP_FORBIDDEN,
    HTTP_FOUND,
    HTTP_INTERNAL_ERROR,
    HTTP_MOVED_PERMANENTLY,
    HTTP_NO_CONTENT,
    HTTP_NOT_FOUND,
    HTTP_OK,
    HTTP_UNAUTHORIZED,
)
from .domain import (
    compute_app_name,
    compute_domain,
    compute_url,
    get_root_domain,
    is_preview_domain,
    is_sub_subdomain,
)
from .output import output
from .port import (
    detect_port,
    get_port,
    read_env_file,
)

__all__ = [
    # client
    "DokployClient",
    "DokployError",
    "DokployAuthError",
    "DokployNotFoundError",
    # config
    "deep_merge",
    "get_environment_config",
    "get_project_name",
    "load_merged_config",
    "load_toml",
    # constants - Enums
    "Environment",
    "SourceType",
    "BuildType",
    "ComposeType",
    "CertificateType",
    "Endpoints",
    # constants - Infrastructure
    "TRAEFIK_SERVER",
    "DEV_SERVER",
    "PROD_SERVER",
    "REGISTRY_HOST",
    "REGISTRY_PORT",
    "REGISTRY_INTERNAL_HOST",
    "DEFAULT_APP_PORT",
    "DEFAULT_SSH_PORT",
    "DEFAULT_SSH_USER",
    # constants - Files
    "DEFAULT_CONFIG_FILE",
    "DEFAULT_ENV_FILE",
    "DEFAULT_DOCKERFILE",
    "DEFAULT_COMPOSE_FILE",
    "APP_PORT_VAR",
    "GITHUB_REPOSITORY_VAR",
    "GITHUB_OUTPUT_VAR",
    # constants - Domains
    "URL_SCHEME_HTTPS",
    "DEV_DOMAIN_PREFIX",
    "PREVIEW_DOMAIN_PREFIX",
    # constants - Timeouts
    "DEFAULT_TIMEOUT",
    "DEPLOY_TIMEOUT",
    "DNS_TIMEOUT",
    "VPS_PROVISION_TIMEOUT",
    "ADMIN_SETUP_TIMEOUT",
    "DEFAULT_RETRY_INTERVAL",
    "DEFAULT_MAX_ATTEMPTS",
    "TAILSCALE_WAIT_TIMEOUT",
    "TAILSCALE_TOKEN_TIMEOUT",
    # constants - Health check
    "DEFAULT_HEALTH_PATH",
    "DEFAULT_HEALTH_INTERVAL",
    "DEFAULT_HEALTH_TIMEOUT",
    "DEFAULT_HEALTH_RETRIES",
    "DEFAULT_HEALTH_START_PERIOD",
    "HEALTH_SUCCESS_CODES",
    # constants - Resources
    "DEFAULT_MEMORY",
    "DEFAULT_MEMORY_LIMIT",
    "DEFAULT_CPU",
    "DEFAULT_CPU_LIMIT",
    "DEV_MEMORY",
    "DEV_MEMORY_LIMIT",
    "DEV_CPU",
    "DEV_CPU_LIMIT",
    "DEFAULT_REPLICAS",
    # constants - Sablier
    "SABLIER_IDLE_TIMEOUT",
    "SABLIER_SESSION_DURATION",
    "SABLIER_STARTUP_TIMEOUT",
    "SABLIER_DEFAULT_THEME",
    # constants - HTTP
    "HEADER_API_KEY",
    "HEADER_CONTENT_TYPE",
    "HEADER_AUTHORIZATION",
    "CONTENT_TYPE_JSON",
    "HTTP_OK",
    "HTTP_CREATED",
    "HTTP_NO_CONTENT",
    "HTTP_MOVED_PERMANENTLY",
    "HTTP_FOUND",
    "HTTP_BAD_REQUEST",
    "HTTP_UNAUTHORIZED",
    "HTTP_FORBIDDEN",
    "HTTP_NOT_FOUND",
    "HTTP_INTERNAL_ERROR",
    # domain
    "compute_app_name",
    "compute_domain",
    "compute_url",
    "get_root_domain",
    "is_preview_domain",
    "is_sub_subdomain",
    # output
    "output",
    # port
    "detect_port",
    "get_port",
    "read_env_file",
]
