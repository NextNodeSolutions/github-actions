"""Domain computation utilities."""


def compute_domain(
    base_domain: str,
    environment: str,
    pr_number: str = "",
) -> str:
    """Compute environment-specific domain.

    Domain patterns:
    - production: {base_domain}
    - development: dev.{base_domain}
    - preview: pr-{pr_number}.dev.{base_domain}
    - other: {environment}.{base_domain}

    Args:
        base_domain: Base domain from config (e.g., "example.com")
        environment: Target environment
        pr_number: PR number for preview environments

    Returns:
        Computed domain string, empty if no base_domain
    """
    if not base_domain:
        return ""

    if environment == "production":
        return base_domain

    if environment == "development":
        return f"dev.{base_domain}"

    if environment == "preview":
        if pr_number:
            return f"pr-{pr_number}.dev.{base_domain}"
        return ""

    return f"{environment}.{base_domain}"


def compute_url(domain: str) -> str:
    """Compute URL from domain.

    Args:
        domain: Domain string

    Returns:
        URL with https:// prefix, empty if no domain
    """
    if not domain:
        return ""

    return f"https://{domain}"


def compute_app_name(
    project_name: str,
    environment: str,
    pr_number: str = "",
) -> str:
    """Compute Dokploy application/compose name.

    Naming patterns:
    - production: {project_name}
    - development: {project_name}-development
    - preview: {project_name}-pr-{pr_number}
    - other: {project_name}-{environment}

    Args:
        project_name: Project name from config
        environment: Target environment
        pr_number: PR number for preview environments

    Returns:
        Application name for Dokploy
    """
    if environment == "production":
        return project_name

    if environment == "preview" and pr_number:
        return f"{project_name}-pr-{pr_number}"

    return f"{project_name}-{environment}"


def is_sub_subdomain(domain: str) -> bool:
    """Check if domain is a sub-subdomain (3+ levels).

    Sub-subdomains like pr-5.dev.example.com cannot use Cloudflare proxy
    because free SSL only covers *.domain.com, not *.subdomain.domain.com.

    Args:
        domain: Domain to check

    Returns:
        True if domain has 2+ dots (sub-subdomain)
    """
    return domain.count(".") >= 2
