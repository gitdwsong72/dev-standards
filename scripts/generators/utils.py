"""Shared utilities for dev-toolkit code generation scripts."""

import re
from pathlib import Path

# Resolve template directory relative to this module
SCRIPT_DIR = Path(__file__).parent.resolve()
TEMPLATE_DIR = SCRIPT_DIR.parent.parent / "templates" / "code-generators"

# Irregular plural -> singular mappings
_IRREGULAR_PLURALS: dict[str, str] = {
    "people": "person",
    "children": "child",
    "men": "man",
    "women": "woman",
    "mice": "mouse",
    "geese": "goose",
    "teeth": "tooth",
    "feet": "foot",
    "data": "datum",
    "criteria": "criterion",
    "analyses": "analysis",
    "indices": "index",
    "matrices": "matrix",
    "vertices": "vertex",
    "appendices": "appendix",
}


def load_template(name: str) -> str:
    """Load a template file from the templates directory.

    Args:
        name: Template filename (e.g., "fastapi_router.py.template")

    Returns:
        Template file contents as string

    Raises:
        ValueError: If the resolved path is outside TEMPLATE_DIR (path traversal attack)
        FileNotFoundError: If the template file does not exist
    """
    template_path = (TEMPLATE_DIR / name).resolve()

    # Path traversal attack defense
    if not template_path.is_relative_to(TEMPLATE_DIR):
        raise ValueError(
            f"Invalid template path: {name}. "
            f"Template must be within {TEMPLATE_DIR}"
        )

    if not template_path.exists():
        raise FileNotFoundError(f"Template not found: {template_path}")

    return template_path.read_text()


def to_pascal_case(s: str) -> str:
    """Convert string to PascalCase."""
    return "".join(word.capitalize() for word in re.split(r"[-_]", s))


def to_singular(s: str) -> str:
    """Singularize a plural noun, handling irregular forms."""
    lower = s.lower()
    if lower in _IRREGULAR_PLURALS:
        # Preserve original casing style
        singular = _IRREGULAR_PLURALS[lower]
        return singular if s == lower else singular.capitalize()
    if s.endswith("ies") and len(s) > 3:
        return s[:-3] + "y"
    if s.endswith("ves"):
        return s[:-3] + "f"
    if s.endswith("ses") or s.endswith("xes") or s.endswith("zes") or s.endswith("ches") or s.endswith("shes"):
        return s[:-2]
    if s.endswith("s") and not s.endswith("ss"):
        return s[:-1]
    return s


def check_overwrite(path: Path, *, force: bool = False) -> bool:
    """Check if a file exists and whether it should be overwritten.

    Returns True if the file should be written, False if it should be skipped.
    Raises FileExistsError if the file exists and force is False.
    """
    if not path.exists():
        return True
    if force:
        return True
    raise FileExistsError(
        f"File already exists: {path}. Use --force to overwrite."
    )
