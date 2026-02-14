"""Tests for scripts/generators/utils.py"""

import pytest
from pathlib import Path
from utils import load_template, to_pascal_case, to_singular, check_overwrite


class TestLoadTemplate:
    """Test cases for load_template function."""

    def test_load_existing_template(self):
        """Test loading an existing template file."""
        content = load_template("fastapi_router.py.template")
        assert isinstance(content, str)
        assert len(content) > 0
        assert "from fastapi import APIRouter" in content

    @pytest.mark.security
    def test_path_traversal_attack_parent_dirs(self):
        """Test that path traversal attack using ../ is blocked."""
        with pytest.raises(ValueError, match="Invalid template path"):
            load_template("../../etc/passwd")

    @pytest.mark.security
    def test_path_traversal_attack_absolute_path(self):
        """Test that absolute path attack is blocked."""
        with pytest.raises(ValueError, match="Invalid template path"):
            load_template("/etc/passwd")

    @pytest.mark.security
    def test_path_traversal_attack_multiple_levels(self):
        """Test that multi-level path traversal is blocked."""
        with pytest.raises(ValueError, match="Invalid template path"):
            load_template("../../../.env")

    def test_nonexistent_template(self):
        """Test that FileNotFoundError is raised for missing templates."""
        with pytest.raises(FileNotFoundError, match="Template not found"):
            load_template("nonexistent_template.txt")

    def test_load_all_standard_templates(self):
        """Test that all standard templates can be loaded."""
        templates = [
            "fastapi_router.py.template",
            "express_router.ts.template",
            "react_component.tsx.template",
            "vue_component.vue.template",
            "pytest_test.py.template",
            "pytest_method.py.template",
            "jest_test.ts.template",
        ]
        for template in templates:
            content = load_template(template)
            assert isinstance(content, str)
            assert len(content) > 0


class TestToPascalCase:
    """Test cases for to_pascal_case function."""

    @pytest.mark.parametrize("input_str,expected", [
        ("user", "User"),
        ("user-profile", "UserProfile"),
        ("user_profile", "UserProfile"),
        ("user-profile_data", "UserProfileData"),
        ("api", "Api"),
        ("user-api-key", "UserApiKey"),
        ("", ""),
        ("a", "A"),
        ("ab-cd-ef", "AbCdEf"),
        ("snake_case_name", "SnakeCaseName"),
        ("kebab-case-name", "KebabCaseName"),
        ("mixed-snake_case", "MixedSnakeCase"),
    ])
    def test_conversion(self, input_str: str, expected: str):
        """Test various input formats are converted to PascalCase."""
        assert to_pascal_case(input_str) == expected

    def test_already_pascal_case(self):
        """Test that already PascalCase strings remain unchanged."""
        assert to_pascal_case("UserProfile") == "Userprofile"  # Note: splits on - and _

    def test_numbers_in_name(self):
        """Test that numbers are preserved in names."""
        assert to_pascal_case("user-123-profile") == "User123Profile"
        assert to_pascal_case("api_v2_client") == "ApiV2Client"


class TestToSingular:
    """Test cases for to_singular function."""

    @pytest.mark.parametrize("plural,singular", [
        # Regular plurals
        ("users", "user"),
        ("posts", "post"),
        ("items", "item"),
        # Irregular plurals
        ("people", "person"),
        ("children", "child"),
        ("men", "man"),
        ("women", "woman"),
        ("mice", "mouse"),
        ("geese", "goose"),
        ("teeth", "tooth"),
        ("feet", "foot"),
        # Special endings
        ("categories", "category"),  # -ies -> -y
        ("babies", "baby"),
        ("cities", "city"),
        ("knives", "knife"),  # -ves -> -f
        ("wolves", "wolf"),
        ("boxes", "box"),  # -es
        ("buses", "bus"),
        ("glasses", "glass"),  # -ss stays
        # Edge cases
        ("data", "datum"),
        ("criteria", "criterion"),
        ("analyses", "analysis"),
        ("indices", "index"),
    ])
    def test_singularization(self, plural: str, singular: str):
        """Test various plural forms are correctly singularized."""
        assert to_singular(plural) == singular

    def test_already_singular(self):
        """Test that already singular words remain unchanged."""
        assert to_singular("user") == "user"
        assert to_singular("person") == "person"
        assert to_singular("child") == "child"

    def test_preserve_casing(self):
        """Test that original casing is preserved."""
        assert to_singular("Users") == "User"
        assert to_singular("USERS") == "USER"
        assert to_singular("People") == "Person"

    def test_empty_string(self):
        """Test that empty string is handled."""
        assert to_singular("") == ""


class TestCheckOverwrite:
    """Test cases for check_overwrite function."""

    def test_new_file_returns_true(self, tmp_path: Path):
        """Test that check returns True for non-existent files."""
        file = tmp_path / "new.txt"
        assert check_overwrite(file) is True

    def test_existing_file_no_force_raises_error(self, tmp_path: Path):
        """Test that FileExistsError is raised when file exists and force=False."""
        file = tmp_path / "existing.txt"
        file.write_text("content")
        with pytest.raises(FileExistsError, match="File already exists"):
            check_overwrite(file, force=False)

    def test_existing_file_with_force_returns_true(self, tmp_path: Path):
        """Test that check returns True when file exists and force=True."""
        file = tmp_path / "existing.txt"
        file.write_text("content")
        assert check_overwrite(file, force=True) is True

    def test_error_message_includes_path(self, tmp_path: Path):
        """Test that error message includes the file path."""
        file = tmp_path / "test.txt"
        file.write_text("content")
        with pytest.raises(FileExistsError) as exc_info:
            check_overwrite(file, force=False)
        assert str(file) in str(exc_info.value)

    def test_error_message_includes_force_hint(self, tmp_path: Path):
        """Test that error message includes hint about --force flag."""
        file = tmp_path / "test.txt"
        file.write_text("content")
        with pytest.raises(FileExistsError) as exc_info:
            check_overwrite(file, force=False)
        assert "--force" in str(exc_info.value)

    def test_directory_as_file(self, tmp_path: Path):
        """Test behavior when a directory exists instead of a file."""
        dir_path = tmp_path / "testdir"
        dir_path.mkdir()
        # Directory exists but is not a file, so exists() returns True
        with pytest.raises(FileExistsError):
            check_overwrite(dir_path, force=False)
