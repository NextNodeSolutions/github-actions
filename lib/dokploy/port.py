"""Port detection utilities."""

import re
from pathlib import Path

from .constants import (
    APP_PORT_VAR,
    DEFAULT_APP_PORT,
    DEFAULT_DOCKERFILE,
    DEFAULT_ENV_FILE,
)


def read_env_file(env_path: str = DEFAULT_ENV_FILE) -> dict[str, str]:
    """Read .env file and return dict of key=value pairs.

    Args:
        env_path: Path to .env file

    Returns:
        Dictionary of environment variables
    """
    env_vars: dict[str, str] = {}
    env_file = Path(env_path)

    if not env_file.exists():
        return env_vars

    for line in env_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, _, value = line.partition("=")
            env_vars[key.strip()] = value.strip().strip("\"'")

    return env_vars


def detect_port(
    env_path: str = DEFAULT_ENV_FILE,
    dockerfile_path: str = DEFAULT_DOCKERFILE,
) -> tuple[int | None, str | None]:
    """Detect application port from multiple sources.

    Priority: .env > Dockerfile ARG > None
    Standard: APP_PORT (NextNode convention)

    Args:
        env_path: Path to .env file
        dockerfile_path: Path to Dockerfile

    Returns:
        Tuple of (port, source) where source indicates where port was found.
        Returns (None, None) if no port detected.
    """
    # 1. Check .env file for APP_PORT
    env_vars = read_env_file(env_path)
    if APP_PORT_VAR in env_vars:
        try:
            return int(env_vars[APP_PORT_VAR]), DEFAULT_ENV_FILE
        except ValueError:
            pass

    # 2. Check Dockerfile for ARG APP_PORT=X
    dockerfile = Path(dockerfile_path)
    if dockerfile.exists():
        content = dockerfile.read_text()
        match = re.search(rf"^ARG\s+{APP_PORT_VAR}\s*=\s*(\d+)", content, re.MULTILINE)
        if match:
            return int(match.group(1)), DEFAULT_DOCKERFILE

    return None, None


def get_port(
    config_port: int | None = None,
    env_path: str = DEFAULT_ENV_FILE,
    dockerfile_path: str = DEFAULT_DOCKERFILE,
    default: int = DEFAULT_APP_PORT,
) -> tuple[int, str]:
    """Get application port with fallback chain.

    Priority: config > .env > Dockerfile > default

    Args:
        config_port: Explicit port from config (highest priority)
        env_path: Path to .env file
        dockerfile_path: Path to Dockerfile
        default: Default port if nothing else found

    Returns:
        Tuple of (port, source) where source describes where port came from
    """
    if config_port is not None:
        return config_port, "config"

    detected_port, source = detect_port(env_path, dockerfile_path)
    if detected_port is not None and source is not None:
        return detected_port, source

    return default, "default"
