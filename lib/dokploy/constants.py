"""Constants and enums for Dokploy operations."""

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


# API Endpoints
class Endpoints:
    """Dokploy API endpoints."""

    # Auth
    AUTH_SIGN_IN = "/api/auth/sign-in/email"

    # Projects
    PROJECT_ALL = "/api/project.all"
    PROJECT_ONE = "/api/project.one"
    PROJECT_CREATE = "/api/project.create"

    # Environments
    ENVIRONMENT_CREATE = "/api/environment.create"

    # Applications
    APPLICATION_CREATE = "/api/application.create"
    APPLICATION_UPDATE = "/api/application.update"
    APPLICATION_DELETE = "/api/application.delete"
    APPLICATION_DEPLOY = "/api/application.deploy"

    # Compose
    COMPOSE_CREATE = "/api/compose.create"
    COMPOSE_UPDATE = "/api/compose.update"
    COMPOSE_DELETE = "/api/compose.delete"
    COMPOSE_DEPLOY = "/api/compose.deploy"

    # Domains
    DOMAIN_CREATE = "/api/domain.create"


# Default values
DEFAULT_TIMEOUT = 30
DEPLOY_TIMEOUT = 60
DEFAULT_PORT = 3000
DEFAULT_HEALTH_PATH = "/health"
DEFAULT_HEALTH_INTERVAL = 30
DEFAULT_HEALTH_TIMEOUT = 10
DEFAULT_HEALTH_RETRIES = 3
DEFAULT_HEALTH_START_PERIOD = 40
