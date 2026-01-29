"""Configuration loading and merging utilities."""

import os
from pathlib import Path
from typing import Any

import tomli


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Deep merge two dicts, override wins on conflicts."""
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def load_toml(path: str | Path) -> dict[str, Any]:
    """Load a TOML file and return its contents as a dict.

    Returns empty dict if file doesn't exist.
    """
    file_path = Path(path)
    if not file_path.exists():
        return {}

    with open(file_path, "rb") as f:
        return tomli.load(f)


def load_merged_config(
    project_config_path: str = "dokploy.toml",
    defaults_path: str = "",
) -> dict[str, Any]:
    """Load and merge project config with defaults.

    Args:
        project_config_path: Path to project's dokploy.toml
        defaults_path: Path to defaults TOML file

    Returns:
        Merged configuration dict
    """
    defaults = {}
    if defaults_path:
        defaults = load_toml(defaults_path)

    project_config = load_toml(project_config_path)

    return deep_merge(defaults, project_config)


def get_project_name(config: dict[str, Any]) -> str:
    """Get project name from config or infer from GITHUB_REPOSITORY.

    Args:
        config: Merged configuration dict

    Returns:
        Project name string
    """
    name = config.get("project", {}).get("name", "")
    if name:
        return name

    github_repo = os.environ.get("GITHUB_REPOSITORY", "")
    if github_repo:
        return github_repo.split("/")[-1]

    return ""


def get_environment_config(
    config: dict[str, Any],
    environment: str,
) -> dict[str, Any]:
    """Get environment-specific configuration.

    For preview environment, falls back to development config.

    Args:
        config: Merged configuration dict
        environment: Target environment name

    Returns:
        Environment configuration dict
    """
    environments = config.get("environments", {})

    if environment == "preview":
        return environments.get("preview", environments.get("development", {}))

    return environments.get(environment, {})
