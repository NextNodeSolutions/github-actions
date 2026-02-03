"""Constants and enums for Dokploy operations.

This package provides centralized constants organized by domain:
- enums: Environment, SourceType, BuildType, etc.
- infrastructure: Servers, registry, ports
- files: Config filenames, env var names
- domains: URL schemes, domain prefixes
- timeouts: All timeout values
- healthcheck: Health check configuration
- resources: Memory, CPU limits
- sablier: Scale-to-zero settings
- http: Headers, status codes
- api: Dokploy API endpoints
"""

from .api import Endpoints
from .domains import (
    DEV_DOMAIN_PREFIX,
    PREVIEW_DOMAIN_PREFIX,
    URL_SCHEME_HTTPS,
)
from .enums import (
    BuildType,
    CertificateType,
    ComposeType,
    Environment,
    SourceType,
)
from .files import (
    APP_PORT_VAR,
    DEFAULT_COMPOSE_FILE,
    DEFAULT_CONFIG_FILE,
    DEFAULT_DOCKERFILE,
    DEFAULT_ENV_FILE,
    GITHUB_OUTPUT_VAR,
    GITHUB_REPOSITORY_VAR,
)
from .healthcheck import (
    DEFAULT_HEALTH_INTERVAL,
    DEFAULT_HEALTH_PATH,
    DEFAULT_HEALTH_RETRIES,
    DEFAULT_HEALTH_START_PERIOD,
    DEFAULT_HEALTH_TIMEOUT,
    HEALTH_SUCCESS_CODES,
)
from .http import (
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
from .infrastructure import (
    DEFAULT_APP_PORT,
    DEFAULT_SSH_KEY_NAME,
    DEFAULT_SSH_PORT,
    DEFAULT_SSH_USER,
    DEV_SERVER,
    PROD_SERVER,
    REGISTRY_HOST,
    REGISTRY_INTERNAL_HOST,
    REGISTRY_PORT,
    TRAEFIK_SERVER,
)
from .resources import (
    DEFAULT_CPU,
    DEFAULT_CPU_LIMIT,
    DEFAULT_MEMORY,
    DEFAULT_MEMORY_LIMIT,
    DEFAULT_REPLICAS,
    DEV_CPU,
    DEV_CPU_LIMIT,
    DEV_MEMORY,
    DEV_MEMORY_LIMIT,
)
from .sablier import (
    SABLIER_DEFAULT_THEME,
    SABLIER_IDLE_TIMEOUT,
    SABLIER_SESSION_DURATION,
    SABLIER_STARTUP_TIMEOUT,
)
from .timeouts import (
    ADMIN_SETUP_TIMEOUT,
    DEFAULT_MAX_ATTEMPTS,
    DEFAULT_RETRY_INTERVAL,
    DEFAULT_TIMEOUT,
    DEPLOY_TIMEOUT,
    DNS_TIMEOUT,
    TAILSCALE_TOKEN_TIMEOUT,
    TAILSCALE_WAIT_TIMEOUT,
    VPS_PROVISION_TIMEOUT,
)

__all__ = [
    # Enums
    "Environment",
    "SourceType",
    "BuildType",
    "ComposeType",
    "CertificateType",
    # API
    "Endpoints",
    # Infrastructure
    "TRAEFIK_SERVER",
    "DEV_SERVER",
    "PROD_SERVER",
    "REGISTRY_HOST",
    "REGISTRY_PORT",
    "REGISTRY_INTERNAL_HOST",
    "DEFAULT_APP_PORT",
    "DEFAULT_SSH_PORT",
    "DEFAULT_SSH_USER",
    "DEFAULT_SSH_KEY_NAME",
    # Files
    "DEFAULT_CONFIG_FILE",
    "DEFAULT_ENV_FILE",
    "DEFAULT_DOCKERFILE",
    "DEFAULT_COMPOSE_FILE",
    "APP_PORT_VAR",
    "GITHUB_REPOSITORY_VAR",
    "GITHUB_OUTPUT_VAR",
    # Domains
    "URL_SCHEME_HTTPS",
    "DEV_DOMAIN_PREFIX",
    "PREVIEW_DOMAIN_PREFIX",
    # Timeouts
    "DEFAULT_TIMEOUT",
    "DEPLOY_TIMEOUT",
    "DNS_TIMEOUT",
    "VPS_PROVISION_TIMEOUT",
    "ADMIN_SETUP_TIMEOUT",
    "DEFAULT_RETRY_INTERVAL",
    "DEFAULT_MAX_ATTEMPTS",
    "TAILSCALE_WAIT_TIMEOUT",
    "TAILSCALE_TOKEN_TIMEOUT",
    # Health check
    "DEFAULT_HEALTH_PATH",
    "DEFAULT_HEALTH_INTERVAL",
    "DEFAULT_HEALTH_TIMEOUT",
    "DEFAULT_HEALTH_RETRIES",
    "DEFAULT_HEALTH_START_PERIOD",
    "HEALTH_SUCCESS_CODES",
    # Resources
    "DEFAULT_MEMORY",
    "DEFAULT_MEMORY_LIMIT",
    "DEFAULT_CPU",
    "DEFAULT_CPU_LIMIT",
    "DEV_MEMORY",
    "DEV_MEMORY_LIMIT",
    "DEV_CPU",
    "DEV_CPU_LIMIT",
    "DEFAULT_REPLICAS",
    # Sablier
    "SABLIER_IDLE_TIMEOUT",
    "SABLIER_SESSION_DURATION",
    "SABLIER_STARTUP_TIMEOUT",
    "SABLIER_DEFAULT_THEME",
    # HTTP
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
]
