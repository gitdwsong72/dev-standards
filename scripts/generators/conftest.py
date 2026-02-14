"""Pytest configuration and shared fixtures for code generators tests."""

import pytest
from pathlib import Path
from typing import Dict


@pytest.fixture
def temp_output_dir(tmp_path: Path) -> Path:
    """Provide a temporary output directory for generated files.

    Args:
        tmp_path: pytest's built-in tmp_path fixture

    Returns:
        Path to a temporary output directory
    """
    output = tmp_path / "output"
    output.mkdir()
    return output


@pytest.fixture
def sample_template_vars() -> Dict[str, str]:
    """Provide sample template variables for testing.

    Returns:
        Dictionary of template variables commonly used in generators
    """
    return {
        "resource": "users",
        "resource_singular": "user",
        "model": "User",
        "name": "UserProfile",
        "name_lower": "userprofile",
        "module": "user_service",
        "class_name": "UserService",
        "func_name": "create_user",
    }


@pytest.fixture
def sample_fastapi_template() -> str:
    """Provide a simple FastAPI template for testing.

    Returns:
        Template string with placeholders
    """
    return """from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/{resource}", tags=["{resource}"])

class {model}Base:
    name: str
"""


@pytest.fixture
def sample_react_template() -> str:
    """Provide a simple React template for testing.

    Returns:
        Template string with placeholders
    """
    return """import React from 'react';

interface {name}Props {{
    title: string;
}}

export const {name}: React.FC<{name}Props> = ({{ title }}) => {{
    return <div>{{title}}</div>;
}};
"""


@pytest.fixture
def sample_pytest_template() -> str:
    """Provide a simple pytest template for testing.

    Returns:
        Template string with placeholders
    """
    return """import pytest
from {module} import {func_name}

class Test{class_name}:
    def test_{func_name}_success(self):
        assert True
"""
