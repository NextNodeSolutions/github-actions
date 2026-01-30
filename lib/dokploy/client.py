"""Dokploy API client with consistent error handling and request patterns."""

import os
from typing import Any

import requests
from requests.exceptions import RequestException


class DokployError(Exception):
    """Base exception for Dokploy API errors."""

    def __init__(self, message: str, status_code: int | None = None, response_text: str | None = None):
        super().__init__(message)
        self.status_code = status_code
        self.response_text = response_text


class DokployAuthError(DokployError):
    """Authentication failed."""


class DokployNotFoundError(DokployError):
    """Resource not found."""


class DokployClient:
    """HTTP client for Dokploy API with consistent error handling.

    Usage:
        client = DokployClient.from_env()
        # or
        client = DokployClient(url="https://dokploy.example.com", token="...")

        # GET request
        projects = client.get("/api/project.all")

        # POST request
        result = client.post("/api/project.create", json={"name": "my-project"})
    """

    DEFAULT_TIMEOUT = 30
    DEPLOY_TIMEOUT = 60

    def __init__(self, url: str, token: str, timeout: int | None = None):
        """Initialize Dokploy client.

        Args:
            url: Dokploy instance URL (trailing slash will be stripped)
            token: Bearer token for authentication
            timeout: Request timeout in seconds (default: 30, configurable via DOKPLOY_TIMEOUT env var)
        """
        self.url = url.rstrip("/")
        self.token = token
        self.timeout = timeout or int(os.environ.get("DOKPLOY_TIMEOUT", str(self.DEFAULT_TIMEOUT)))

    @classmethod
    def from_env(cls) -> "DokployClient":
        """Create client from environment variables.

        Required env vars:
            DOKPLOY_URL: Dokploy instance URL
            DOKPLOY_TOKEN: Bearer token

        Optional env vars:
            DOKPLOY_TIMEOUT: Request timeout in seconds (default: 30)
        """
        url = os.environ.get("DOKPLOY_URL")
        token = os.environ.get("DOKPLOY_TOKEN")

        if not url:
            raise ValueError("DOKPLOY_URL environment variable is required")
        if not token:
            raise ValueError("DOKPLOY_TOKEN environment variable is required")

        return cls(url=url, token=token)

    @property
    def _headers(self) -> dict[str, str]:
        """Standard headers for all requests."""
        return {
            "x-api-key": self.token,
            "Content-Type": "application/json",
        }

    def _handle_response(self, response: requests.Response, raise_for_status: bool = True) -> requests.Response:
        """Handle response with consistent error handling.

        Args:
            response: The response object
            raise_for_status: Whether to raise on non-2xx status codes

        Returns:
            The response object

        Raises:
            DokployAuthError: On 401 status
            DokployNotFoundError: On 404 status
            DokployError: On other non-2xx status codes (if raise_for_status=True)
        """
        if response.status_code == 401:
            raise DokployAuthError(
                "Authentication failed - invalid or expired token",
                status_code=401,
                response_text=response.text,
            )

        if response.status_code == 404:
            raise DokployNotFoundError(
                "Resource not found",
                status_code=404,
                response_text=response.text,
            )

        if raise_for_status and not response.ok:
            raise DokployError(
                f"API request failed: {response.status_code}",
                status_code=response.status_code,
                response_text=response.text,
            )

        return response

    def get(
        self,
        endpoint: str,
        params: dict[str, Any] | None = None,
        timeout: int | None = None,
        raise_for_status: bool = True,
    ) -> dict[str, Any] | list[Any]:
        """Make GET request to Dokploy API.

        Args:
            endpoint: API endpoint (e.g., "/api/project.all")
            params: Query parameters
            timeout: Override default timeout
            raise_for_status: Whether to raise on non-2xx status codes

        Returns:
            JSON response data

        Raises:
            DokployError: On API errors
            RequestException: On network errors
        """
        try:
            response = requests.get(
                f"{self.url}{endpoint}",
                headers=self._headers,
                params=params,
                timeout=timeout or self.timeout,
            )
            self._handle_response(response, raise_for_status=raise_for_status)
            return response.json() if response.text else {}
        except RequestException as e:
            raise DokployError(f"Request failed: {e}") from e

    def post(
        self,
        endpoint: str,
        json: dict[str, Any] | None = None,
        timeout: int | None = None,
        raise_for_status: bool = True,
    ) -> dict[str, Any] | list[Any]:
        """Make POST request to Dokploy API.

        Args:
            endpoint: API endpoint (e.g., "/api/project.create")
            json: JSON body data
            timeout: Override default timeout
            raise_for_status: Whether to raise on non-2xx status codes

        Returns:
            JSON response data

        Raises:
            DokployError: On API errors
            RequestException: On network errors
        """
        try:
            response = requests.post(
                f"{self.url}{endpoint}",
                headers=self._headers,
                json=json,
                timeout=timeout or self.timeout,
            )
            self._handle_response(response, raise_for_status=raise_for_status)
            return response.json() if response.text else {}
        except RequestException as e:
            raise DokployError(f"Request failed: {e}") from e

    def verify_token(self) -> bool:
        """Verify the current token is valid.

        Returns:
            True if token is valid

        Raises:
            DokployAuthError: If token is invalid
        """
        self.get("/api/project.all")
        return True

    # =========================================================================
    # Server Management
    # =========================================================================

    def list_servers(self) -> list[dict[str, Any]]:
        """Get all servers registered in Dokploy.

        Returns:
            List of server objects with serverId, name, ipAddress, etc.
        """
        result = self.get("/api/server.all")
        return result if isinstance(result, list) else []

    def get_server_by_name(self, name: str) -> dict[str, Any] | None:
        """Find a server by name.

        Args:
            name: Server name to find

        Returns:
            Server object if found, None otherwise
        """
        servers = self.list_servers()
        for server in servers:
            if server.get("name") == name:
                return server
        return None

    def create_server(
        self,
        name: str,
        ip_address: str,
        ssh_key_id: str,
        port: int = 22,
        username: str = "root",
        server_type: str = "deploy",
    ) -> dict[str, Any]:
        """Create a new server in Dokploy.

        Args:
            name: Server name
            ip_address: Server IP address (Tailscale IP recommended)
            ssh_key_id: Dokploy SSH key ID for server access
            port: SSH port (default: 22)
            username: SSH username (default: root)
            server_type: Server type (default: deploy)

        Returns:
            Created server object with serverId
        """
        payload = {
            "name": name,
            "ipAddress": ip_address,
            "port": port,
            "username": username,
            "sshKeyId": ssh_key_id,
            "serverType": server_type,
        }
        wrapped = {"0": {"json": payload}}
        result = self.post("/api/trpc/server.create?batch=1", json=wrapped)

        if isinstance(result, list) and len(result) > 0:
            data = result[0].get("result", {}).get("data", {})
            return data.get("json", data)
        return result if isinstance(result, dict) else {}

    def setup_server(self, server_id: str) -> None:
        """Setup a server (install Docker + Swarm).

        Args:
            server_id: Dokploy server ID
        """
        payload = {"serverId": server_id}
        wrapped = {"0": {"json": payload}}
        self.post("/api/trpc/server.setup?batch=1", json=wrapped)

    def update_server(
        self,
        server_id: str,
        ip_address: str | None = None,
        name: str | None = None,
        port: int | None = None,
        username: str | None = None,
    ) -> dict[str, Any]:
        """Update an existing server in Dokploy.

        Args:
            server_id: Dokploy server ID
            ip_address: New IP address (optional)
            name: New server name (optional)
            port: New SSH port (optional)
            username: New SSH username (optional)

        Returns:
            Updated server object
        """
        from .constants import Endpoints

        payload: dict[str, Any] = {"serverId": server_id}
        if ip_address is not None:
            payload["ipAddress"] = ip_address
        if name is not None:
            payload["name"] = name
        if port is not None:
            payload["port"] = port
        if username is not None:
            payload["username"] = username

        wrapped = {"0": {"json": payload}}
        result = self.post(Endpoints.SERVER_UPDATE, json=wrapped)

        if isinstance(result, list) and len(result) > 0:
            data = result[0].get("result", {}).get("data", {})
            return data.get("json", data)
        return result if isinstance(result, dict) else {}

    # =========================================================================
    # SSH Key Management
    # =========================================================================

    def list_ssh_keys(self) -> list[dict[str, Any]]:
        """Get all SSH keys in Dokploy.

        Returns:
            List of SSH key objects with sshKeyId, name, etc.
        """
        result = self.get("/api/sshKey.all")
        return result if isinstance(result, list) else []

    def get_ssh_key_by_name(self, name: str) -> dict[str, Any] | None:
        """Find an SSH key by name.

        Args:
            name: SSH key name to find

        Returns:
            SSH key object if found, None otherwise
        """
        keys = self.list_ssh_keys()
        for key in keys:
            if key.get("name") == name:
                return key
        return None
