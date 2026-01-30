"""Dokploy API endpoints."""


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
    DOMAIN_BY_COMPOSE_ID = "/api/domain.byComposeId"
    DOMAIN_BY_APPLICATION_ID = "/api/domain.byApplicationId"

    # Mounts
    MOUNT_CREATE = "/api/mounts.create"

    # Servers
    SERVER_UPDATE = "/api/trpc/server.update?batch=1"
