"""Tests for scripts/generators/generate_component.py"""

import pytest
from pathlib import Path
from generate_component import (
    validate_component_name,
    generate_react,
    generate_vue,
)


class TestValidateComponentName:
    """Test cases for validate_component_name function."""

    def test_valid_pascal_case_name(self):
        """Test that PascalCase names are valid."""
        validate_component_name("UserProfile")
        validate_component_name("Button")
        validate_component_name("DataTable")

    def test_valid_name_with_numbers(self):
        """Test that names with numbers are valid."""
        validate_component_name("UserProfile2")
        validate_component_name("Grid3D")

    def test_empty_name_raises_error(self):
        """Test that empty names raise ValueError."""
        with pytest.raises(ValueError, match="cannot be empty"):
            validate_component_name("")

    def test_lowercase_start_raises_error(self):
        """Test that names starting with lowercase raise ValueError."""
        with pytest.raises(ValueError, match="PascalCase"):
            validate_component_name("userProfile")

    def test_snake_case_raises_error(self):
        """Test that snake_case names raise ValueError."""
        with pytest.raises(ValueError, match="alphanumeric"):
            validate_component_name("user_profile")

    def test_kebab_case_raises_error(self):
        """Test that kebab-case names raise ValueError."""
        with pytest.raises(ValueError, match="alphanumeric"):
            validate_component_name("user-profile")

    def test_name_with_spaces_raises_error(self):
        """Test that names with spaces raise ValueError."""
        with pytest.raises(ValueError, match="alphanumeric"):
            validate_component_name("User Profile")

    @pytest.mark.security
    def test_name_with_curly_braces_raises_error(self):
        """Test that template injection with curly braces is blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_component_name("User{evil}")

    @pytest.mark.security
    def test_name_with_opening_brace_only_raises_error(self):
        """Test that even single brace is blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_component_name("User{")

    @pytest.mark.security
    def test_name_with_code_injection_raises_error(self):
        """Test that code injection attempts are blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_component_name("{__import__('os')}")


class TestGenerateReact:
    """Test cases for generate_react function."""

    def test_generate_basic_component(self, temp_output_dir: Path):
        """Test generating a basic React component."""
        created_files = generate_react("UserProfile", temp_output_dir)

        # Verify list of files returned
        assert isinstance(created_files, list)
        assert len(created_files) >= 2  # At least component + index

        # Check directory structure
        output_dir = created_files[0].parent
        assert output_dir.exists()
        assert output_dir.is_dir()
        assert output_dir.name == "UserProfile"

        # Check component file
        component_file = output_dir / "UserProfile.tsx"
        assert component_file.exists()
        assert component_file in created_files
        content = component_file.read_text()

        # Check React imports
        assert "import React" in content or "import" in content

        # Check component definition
        assert "UserProfile" in content
        assert "interface UserProfileProps" in content or "type UserProfileProps" in content

    def test_generate_component_with_index(self, temp_output_dir: Path):
        """Test that index.ts file is generated."""
        created_files = generate_react("Button", temp_output_dir)

        output_dir = created_files[0].parent
        index_file = output_dir / "index.ts"
        assert index_file.exists()
        assert index_file in created_files
        content = index_file.read_text()

        # Check that it exports the component
        assert "Button" in content
        assert "export" in content

    def test_generate_with_test(self, temp_output_dir: Path):
        """Test generating component with test file."""
        created_files = generate_react("UserCard", temp_output_dir, with_test=True)

        output_dir = created_files[0].parent
        test_file = output_dir / "UserCard.test.tsx"
        assert test_file.exists()
        assert test_file in created_files
        assert len(created_files) == 3  # component + test + index
        content = test_file.read_text()

        # Check test structure
        assert "UserCard" in content
        assert "describe" in content or "test" in content or "it(" in content
        assert "@testing-library/react" in content or "vitest" in content

    def test_generate_without_test(self, temp_output_dir: Path):
        """Test generating component without test file."""
        created_files = generate_react("UserCard", temp_output_dir, with_test=False)

        output_dir = created_files[0].parent
        assert len(created_files) == 2  # component + index only
        test_file = output_dir / "UserCard.test.tsx"
        assert not test_file.exists()

    def test_dry_run_mode(self, temp_output_dir: Path, capsys):
        """Test that dry-run mode doesn't create files."""
        created_files = generate_react("UserProfile", temp_output_dir, dry_run=True)

        # Files should not be created
        assert all(not f.exists() for f in created_files)

        # Should print what would be created
        captured = capsys.readouterr()
        assert "[dry-run]" in captured.out
        assert "UserProfile" in captured.out

    def test_force_overwrite(self, temp_output_dir: Path):
        """Test that force flag allows overwriting existing files."""
        created_files = generate_react("Button", temp_output_dir)
        output_dir = created_files[0].parent
        component_file = output_dir / "Button.tsx"
        assert component_file.exists()

        # Generate again with force=True
        created_files2 = generate_react("Button", temp_output_dir, force=True)
        output_dir2 = created_files2[0].parent
        assert output_dir2 == output_dir
        assert component_file.exists()

    def test_overwrite_without_force_raises_error(self, temp_output_dir: Path):
        """Test that generating over existing directory without force raises error."""
        generate_react("Button", temp_output_dir)

        with pytest.raises(FileExistsError):
            generate_react("Button", temp_output_dir, force=False)


class TestGenerateVue:
    """Test cases for generate_vue function."""

    def test_generate_basic_component(self, temp_output_dir: Path):
        """Test generating a basic Vue component."""
        created_files = generate_vue("UserProfile", temp_output_dir)

        assert isinstance(created_files, list)
        assert len(created_files) >= 1
        output_path = created_files[0]
        assert output_path.exists()
        assert output_path.name == "UserProfile.vue"
        content = output_path.read_text()

        # Check Vue SFC structure
        assert "<template>" in content
        assert "<script" in content
        assert "<style" in content

        # Check component name
        assert "UserProfile" in content

    def test_generate_composition_api(self, temp_output_dir: Path):
        """Test that Vue 3 Composition API is used."""
        created_files = generate_vue("Button", temp_output_dir)

        output_path = created_files[0]
        content = output_path.read_text()
        # Check for Composition API patterns
        assert "<script setup" in content or "setup()" in content

    def test_generate_with_typescript(self, temp_output_dir: Path):
        """Test that generated Vue component uses TypeScript."""
        created_files = generate_vue("UserCard", temp_output_dir)

        output_path = created_files[0]
        content = output_path.read_text()
        # Check for TypeScript
        assert '<script setup lang="ts">' in content or "lang=\"ts\"" in content

    def test_dry_run_mode(self, temp_output_dir: Path, capsys):
        """Test that dry-run mode doesn't create files for Vue."""
        created_files = generate_vue("UserProfile", temp_output_dir, dry_run=True)

        output_path = created_files[0]
        assert not output_path.exists()

        captured = capsys.readouterr()
        assert "[dry-run]" in captured.out
        assert "UserProfile.vue" in captured.out


class TestIntegration:
    """Integration tests for component generation."""

    @pytest.mark.integration
    def test_generate_multiple_react_components(self, temp_output_dir: Path):
        """Test generating multiple React components."""
        components = ["UserCard", "PostList", "CommentItem"]

        for component in components:
            created_files = generate_react(component, temp_output_dir)
            assert len(created_files) >= 2

        # Check all directories were created
        assert (temp_output_dir / "UserCard").exists()
        assert (temp_output_dir / "PostList").exists()
        assert (temp_output_dir / "CommentItem").exists()

    @pytest.mark.integration
    def test_generate_react_and_vue_components(self, temp_output_dir: Path):
        """Test generating both React and Vue components."""
        react_dir = temp_output_dir / "react"
        vue_dir = temp_output_dir / "vue"
        react_dir.mkdir()
        vue_dir.mkdir()

        react_files = generate_react("Button", react_dir)
        vue_files = generate_vue("Button", vue_dir)

        assert len(react_files) >= 2
        assert len(vue_files) >= 1
        assert (react_dir / "Button" / "Button.tsx").exists()
        assert (vue_dir / "Button.vue").exists()

    @pytest.mark.integration
    def test_generated_react_code_is_valid_typescript(self, temp_output_dir: Path):
        """Test that generated React code is syntactically valid TypeScript."""
        created_files = generate_react("UserProfile", temp_output_dir)
        output_dir = created_files[0].parent
        component_file = output_dir / "UserProfile.tsx"

        content = component_file.read_text()
        # Basic syntax check - should not have obvious syntax errors
        assert content.count("{") == content.count("}")
        assert content.count("(") == content.count(")")
        assert content.count("[") == content.count("]")
        assert "import" in content
        assert "export" in content
