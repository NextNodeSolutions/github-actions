"""GitHub Actions output utilities."""

import os
import uuid


def output(key: str, value: str) -> None:
    """Write a key-value pair to GitHub Actions output file.

    Handles multiline values using heredoc syntax.
    """
    github_output = os.environ.get("GITHUB_OUTPUT", "")
    if not github_output:
        return

    with open(github_output, "a") as f:
        if "\n" in str(value):
            delimiter = f"EOF_{uuid.uuid4().hex[:8]}"
            f.write(f"{key}<<{delimiter}\n{value}\n{delimiter}\n")
        else:
            f.write(f"{key}={value}\n")
