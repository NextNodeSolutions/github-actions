"""Enums for Dokploy operations."""

from enum import Enum


class Environment(str, Enum):
    """Dokploy environment types."""

    PRODUCTION = "production"
    STAGING = "staging"
    DEVELOPMENT = "development"
    PREVIEW = "preview"

    @classmethod
    def from_string(cls, value: str) -> "Environment":
        """Get environment from string, case-insensitive.

        Args:
            value: Environment name string

        Returns:
            Matching Environment enum value

        Raises:
            ValueError: If no matching environment found
        """
        value_lower = value.lower()
        for env in cls:
            if env.value == value_lower:
                return env
        raise ValueError(f"Unknown environment: {value}")


class SourceType(str, Enum):
    """Application source types."""

    DOCKER = "docker"
    GITHUB = "github"
    GITLAB = "gitlab"
    BITBUCKET = "bitbucket"
    RAW = "raw"


class BuildType(str, Enum):
    """Application build types."""

    DOCKERFILE = "dockerfile"
    NIXPACKS = "nixpacks"
    HEROKU = "heroku"
    PAKETO = "paketo"
    STATIC = "static"


class ComposeType(str, Enum):
    """Compose stack types."""

    DOCKER_COMPOSE = "docker-compose"
    STACK = "stack"


class CertificateType(str, Enum):
    """SSL certificate types."""

    LETSENCRYPT = "letsencrypt"
    NONE = "none"
