"""Shared Python utilities for Dokploy GitHub Actions.

This library provides reusable functions for:
- Configuration loading and merging
- Domain computation
- Port detection
- GitHub Actions output handling
- Dokploy API client with consistent error handling
- Constants and enums for Dokploy operations
"""

from lib.dokploy.client import (
    DokployAuthError,
    DokployClient,
    DokployError,
    DokployNotFoundError,
)
from lib.dokploy.config import (
    deep_merge,
    get_environment_config,
    get_project_name,
    load_merged_config,
    load_toml,
)
from lib.dokploy.constants import (
    DEFAULT_HEALTH_INTERVAL,
    DEFAULT_HEALTH_PATH,
    DEFAULT_HEALTH_RETRIES,
    DEFAULT_HEALTH_START_PERIOD,
    DEFAULT_HEALTH_TIMEOUT,
    DEFAULT_PORT,
    DEFAULT_TIMEOUT,
    DEPLOY_TIMEOUT,
    BuildType,
    CertificateType,
    ComposeType,
    Endpoints,
    Environment,
    SourceType,
)
from lib.dokploy.domain import (
    compute_app_name,
    compute_domain,
    compute_url,
    is_sub_subdomain,
)
from lib.dokploy.output import output
from lib.dokploy.port import (
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
    # constants
    "Environment",
    "SourceType",
    "BuildType",
    "ComposeType",
    "CertificateType",
    "Endpoints",
    "DEFAULT_TIMEOUT",
    "DEPLOY_TIMEOUT",
    "DEFAULT_PORT",
    "DEFAULT_HEALTH_PATH",
    "DEFAULT_HEALTH_INTERVAL",
    "DEFAULT_HEALTH_TIMEOUT",
    "DEFAULT_HEALTH_RETRIES",
    "DEFAULT_HEALTH_START_PERIOD",
    # domain
    "compute_app_name",
    "compute_domain",
    "compute_url",
    "is_sub_subdomain",
    # output
    "output",
    # port
    "detect_port",
    "get_port",
    "read_env_file",
]
