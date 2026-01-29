"""Shared Python utilities for Dokploy GitHub Actions.

This library provides reusable functions for:
- Configuration loading and merging
- Domain computation
- Port detection
- GitHub Actions output handling
"""

from lib.dokploy.config import (
    deep_merge,
    get_environment_config,
    get_project_name,
    load_merged_config,
    load_toml,
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
    # config
    "deep_merge",
    "get_environment_config",
    "get_project_name",
    "load_merged_config",
    "load_toml",
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
