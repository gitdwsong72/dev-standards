"""Company Python Standards Package.

This package provides standardized configurations for Python development tools.
"""

__version__ = "1.0.0"

from pathlib import Path

PACKAGE_DIR = Path(__file__).parent


def get_ruff_config_path() -> Path:
    """Return the path to the Ruff configuration file."""
    return PACKAGE_DIR / "ruff.toml"


def get_mypy_config_path() -> Path:
    """Return the path to the mypy configuration file."""
    return PACKAGE_DIR / "mypy.ini"
