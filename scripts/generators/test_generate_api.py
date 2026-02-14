"""Tests for scripts/generators/generate_api.py"""

import pytest
from pathlib import Path
from generate_api import (
    validate_resource_name,
    generate_fastapi,
    generate_express,
)


class TestValidateResourceName:
    """Test cases for validate_resource_name function."""

    def test_valid_lowercase_name(self):
        """Test that lowercase alphanumeric names are valid."""
        validate_resource_name("users")
        validate_resource_name("posts")
        validate_resource_name("items")

    def test_valid_name_with_underscores(self):
        """Test that names with underscores are valid."""
        validate_resource_name("user_profiles")
        validate_resource_name("api_keys")

    def test_valid_name_with_hyphens(self):
        """Test that names with hyphens are valid."""
        validate_resource_name("user-profiles")
        validate_resource_name("api-keys")

    def test_valid_mixed_separators(self):
        """Test that mixed underscores and hyphens are valid."""
        validate_resource_name("user-profile_data")

    def test_empty_name_raises_error(self):
        """Test that empty names raise ValueError."""
        with pytest.raises(ValueError, match="cannot be empty"):
            validate_resource_name("")

    def test_name_with_spaces_raises_error(self):
        """Test that names with spaces raise ValueError."""
        with pytest.raises(ValueError, match="Invalid resource name"):
            validate_resource_name("user profiles")

    def test_name_with_special_chars_raises_error(self):
        """Test that names with special characters raise ValueError."""
        invalid_names = [
            "user@profile",
            "user#profile",
            "user$profile",
            "user.profile",
            "user/profile",
            "user\\profile",
        ]
        for name in invalid_names:
            with pytest.raises(ValueError, match="Invalid resource name"):
                validate_resource_name(name)

    @pytest.mark.security
    def test_name_with_curly_braces_raises_error(self):
        """Test that template injection with curly braces is blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_resource_name("{evil}")

    @pytest.mark.security
    def test_name_with_python_code_injection_raises_error(self):
        """Test that Python code injection attempts are blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_resource_name("{__import__('os')}")

    @pytest.mark.security
    def test_name_with_format_string_injection_raises_error(self):
        """Test that format string injection attempts are blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_resource_name("user{evil}profile")


class TestGenerateFastAPI:
    """Test cases for generate_fastapi function."""

    def test_generate_basic_router(self, temp_output_dir: Path):
        """Test generating a basic FastAPI router."""
        output_path = generate_fastapi("users", temp_output_dir)

        assert output_path.exists()
        assert output_path.name == "users_router.py"
        content = output_path.read_text()

        # Check essential FastAPI imports
        assert "from fastapi import APIRouter" in content
        assert "from pydantic import BaseModel" in content

        # Check router definition
        assert 'router = APIRouter(prefix="/api/v1/users"' in content
        assert 'tags=["users"]' in content

        # Check model classes
        assert "class UserBase" in content
        assert "class User" in content or "class UserCreate" in content

    def test_generate_with_plurals(self, temp_output_dir: Path):
        """Test that plurals are handled correctly."""
        output_path = generate_fastapi("posts", temp_output_dir)

        content = output_path.read_text()
        # Should singularize 'posts' to 'post'
        assert "class PostBase" in content or "class Post" in content
        assert 'prefix="/api/v1/posts"' in content

    def test_generate_with_hyphens(self, temp_output_dir: Path):
        """Test resource names with hyphens."""
        output_path = generate_fastapi("user-profiles", temp_output_dir)

        assert output_path.name == "user-profiles_router.py"
        content = output_path.read_text()
        assert "UserProfile" in content  # Should convert to PascalCase

    def test_dry_run_mode(self, temp_output_dir: Path, capsys):
        """Test that dry-run mode doesn't create files."""
        output_path = generate_fastapi("users", temp_output_dir, dry_run=True)

        # File should not be created
        assert not output_path.exists()

        # Should print what would be created
        captured = capsys.readouterr()
        assert "[dry-run]" in captured.out
        assert "users_router.py" in captured.out

    def test_force_overwrite(self, temp_output_dir: Path):
        """Test that force flag allows overwriting existing files."""
        output_path = generate_fastapi("users", temp_output_dir)
        assert output_path.exists()

        original_content = output_path.read_text()

        # Generate again with force=True
        output_path2 = generate_fastapi("users", temp_output_dir, force=True)
        assert output_path2 == output_path
        assert output_path2.exists()

    def test_overwrite_without_force_raises_error(self, temp_output_dir: Path):
        """Test that generating over existing file without force raises error."""
        generate_fastapi("users", temp_output_dir)

        with pytest.raises(FileExistsError):
            generate_fastapi("users", temp_output_dir, force=False)


class TestGenerateExpress:
    """Test cases for generate_express function."""

    def test_generate_basic_router(self, temp_output_dir: Path):
        """Test generating a basic Express router."""
        output_path = generate_express("users", temp_output_dir)

        assert output_path.exists()
        assert output_path.name == "users.router.ts"
        content = output_path.read_text()

        # Check essential Express imports
        assert "import { Router" in content or "from 'express'" in content

        # Check router definition
        assert "Router()" in content

        # Check CRUD endpoints
        assert "router.get" in content
        assert "router.post" in content

    def test_generate_with_plurals(self, temp_output_dir: Path):
        """Test that plurals are handled correctly for Express."""
        output_path = generate_express("posts", temp_output_dir)

        content = output_path.read_text()
        # Should singularize 'posts' to 'post'
        assert "Post" in content
        assert output_path.name == "posts.router.ts"

    def test_dry_run_mode(self, temp_output_dir: Path, capsys):
        """Test that dry-run mode doesn't create files for Express."""
        output_path = generate_express("users", temp_output_dir, dry_run=True)

        assert not output_path.exists()

        captured = capsys.readouterr()
        assert "[dry-run]" in captured.out
        assert "users.router.ts" in captured.out


class TestIntegration:
    """Integration tests for API generation."""

    @pytest.mark.integration
    def test_generate_multiple_resources(self, temp_output_dir: Path):
        """Test generating multiple API resources."""
        resources = ["users", "posts", "comments"]

        for resource in resources:
            generate_fastapi(resource, temp_output_dir)

        # Check all files were created
        assert (temp_output_dir / "users_router.py").exists()
        assert (temp_output_dir / "posts_router.py").exists()
        assert (temp_output_dir / "comments_router.py").exists()

    @pytest.mark.integration
    def test_generated_code_is_valid_python(self, temp_output_dir: Path):
        """Test that generated FastAPI code is syntactically valid Python."""
        output_path = generate_fastapi("users", temp_output_dir)

        # Try to compile the generated code
        content = output_path.read_text()
        try:
            compile(content, str(output_path), 'exec')
        except SyntaxError as e:
            pytest.fail(f"Generated code has syntax error: {e}")
