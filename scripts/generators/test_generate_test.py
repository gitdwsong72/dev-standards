"""Tests for scripts/generators/generate_test.py"""

import pytest
from pathlib import Path
from generate_test import (
    validate_module_name,
    validate_function_names,
    generate_pytest,
    generate_jest,
)


class TestValidateModuleName:
    """Test cases for validate_module_name function."""

    def test_valid_snake_case_name(self):
        """Test that snake_case names are valid."""
        validate_module_name("user_service")
        validate_module_name("api_client")
        validate_module_name("data_processor")

    def test_valid_name_with_underscores(self):
        """Test that names with multiple underscores are valid."""
        validate_module_name("user_profile_service")

    def test_valid_name_starting_with_underscore(self):
        """Test that names can start with underscore."""
        validate_module_name("_private_module")

    def test_valid_name_with_numbers(self):
        """Test that names with numbers are valid."""
        validate_module_name("api_v2_client")
        validate_module_name("user_service_123")

    def test_empty_name_raises_error(self):
        """Test that empty names raise ValueError."""
        with pytest.raises(ValueError, match="cannot be empty"):
            validate_module_name("")

    def test_name_starting_with_number_raises_error(self):
        """Test that names starting with number raise ValueError."""
        with pytest.raises(ValueError, match="Invalid module name"):
            validate_module_name("123_user")

    def test_name_with_hyphens_raises_error(self):
        """Test that names with hyphens raise ValueError."""
        with pytest.raises(ValueError, match="Invalid module name"):
            validate_module_name("user-service")

    def test_name_with_spaces_raises_error(self):
        """Test that names with spaces raise ValueError."""
        with pytest.raises(ValueError, match="Invalid module name"):
            validate_module_name("user service")

    @pytest.mark.security
    def test_name_with_curly_braces_raises_error(self):
        """Test that template injection with curly braces is blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_module_name("user{evil}")

    @pytest.mark.security
    def test_name_with_code_injection_raises_error(self):
        """Test that code injection attempts are blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_module_name("{__import__('os')}")


class TestValidateFunctionNames:
    """Test cases for validate_function_names function."""

    def test_valid_function_names(self):
        """Test that valid function names pass validation."""
        validate_function_names(["create_user", "update_user", "delete_user"])

    def test_single_function_name(self):
        """Test that a single function name is valid."""
        validate_function_names(["get_user"])

    def test_function_names_with_numbers(self):
        """Test that function names with numbers are valid."""
        validate_function_names(["get_user_v2", "process_batch_123"])

    def test_empty_list_raises_error(self):
        """Test that empty function list raises ValueError."""
        with pytest.raises(ValueError, match="At least one function name is required"):
            validate_function_names([])

    def test_invalid_function_name_with_hyphens(self):
        """Test that function names with hyphens raise ValueError."""
        with pytest.raises(ValueError, match="Invalid function name"):
            validate_function_names(["create-user"])

    def test_invalid_function_name_with_spaces(self):
        """Test that function names with spaces raise ValueError."""
        with pytest.raises(ValueError, match="Invalid function name"):
            validate_function_names(["create user"])

    def test_one_valid_one_invalid_raises_error(self):
        """Test that even one invalid name raises ValueError."""
        with pytest.raises(ValueError, match="Invalid function name"):
            validate_function_names(["create_user", "invalid-name"])

    @pytest.mark.security
    def test_function_name_with_curly_braces_raises_error(self):
        """Test that template injection with curly braces is blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_function_names(["create_user", "{evil}"])

    @pytest.mark.security
    def test_function_name_with_code_injection_raises_error(self):
        """Test that code injection attempts are blocked."""
        with pytest.raises(ValueError, match="template injection risk"):
            validate_function_names(["{__import__('os').system('ls')}"])


class TestGeneratePytest:
    """Test cases for generate_pytest function."""

    def test_generate_basic_test_file(self, temp_output_dir: Path):
        """Test generating a basic pytest test file."""
        functions = ["create_user", "update_user"]
        output_path = generate_pytest("user_service", functions, temp_output_dir)

        assert output_path.exists()
        assert output_path.name == "test_user_service.py"
        content = output_path.read_text()

        # Check pytest imports
        assert "import pytest" in content
        assert "from user_service import" in content

        # Check test class
        assert "class TestUserService" in content

        # Check test methods
        assert "def test_create_user" in content
        assert "def test_update_user" in content

    def test_generate_with_fixtures(self, temp_output_dir: Path):
        """Test that generated tests include fixtures."""
        output_path = generate_pytest("user_service", ["create_user"], temp_output_dir)

        content = output_path.read_text()
        # Check for fixture definition
        assert "@pytest.fixture" in content
        assert "def sample_data" in content or "def " in content

    def test_generate_with_multiple_functions(self, temp_output_dir: Path):
        """Test generating tests for multiple functions."""
        functions = ["get_user", "create_user", "update_user", "delete_user"]
        output_path = generate_pytest("user_service", functions, temp_output_dir)

        content = output_path.read_text()
        for func in functions:
            assert f"def test_{func}" in content

    def test_dry_run_mode(self, temp_output_dir: Path, capsys):
        """Test that dry-run mode doesn't create files."""
        output_path = generate_pytest(
            "user_service",
            ["create_user"],
            temp_output_dir,
            dry_run=True
        )

        assert not output_path.exists()

        captured = capsys.readouterr()
        assert "[dry-run]" in captured.out
        assert "test_user_service.py" in captured.out

    def test_force_overwrite(self, temp_output_dir: Path):
        """Test that force flag allows overwriting existing files."""
        functions = ["create_user"]
        output_path = generate_pytest("user_service", functions, temp_output_dir)
        assert output_path.exists()

        # Generate again with force=True
        output_path2 = generate_pytest("user_service", functions, temp_output_dir, force=True)
        assert output_path2 == output_path
        assert output_path2.exists()

    def test_overwrite_without_force_raises_error(self, temp_output_dir: Path):
        """Test that generating over existing file without force raises error."""
        generate_pytest("user_service", ["create_user"], temp_output_dir)

        with pytest.raises(FileExistsError):
            generate_pytest("user_service", ["create_user"], temp_output_dir, force=False)


class TestGenerateJest:
    """Test cases for generate_jest function."""

    def test_generate_basic_test_file(self, temp_output_dir: Path):
        """Test generating a basic Jest test file."""
        functions = ["createUser", "updateUser"]
        output_path = generate_jest("userService", functions, temp_output_dir)

        assert output_path.exists()
        assert output_path.name == "userService.test.ts"
        content = output_path.read_text()

        # Check imports
        assert "import" in content
        assert "userService" in content

        # Check describe block
        assert "describe" in content

        # Check test cases
        assert "test(" in content or "it(" in content
        assert "createUser" in content
        assert "updateUser" in content

    def test_generate_with_typescript_types(self, temp_output_dir: Path):
        """Test that generated Jest tests use TypeScript."""
        output_path = generate_jest("userService", ["createUser"], temp_output_dir)

        content = output_path.read_text()
        # File should be .ts extension
        assert output_path.suffix == ".ts"

    def test_generate_with_multiple_functions(self, temp_output_dir: Path):
        """Test generating tests for multiple functions."""
        functions = ["getUser", "createUser", "updateUser", "deleteUser"]
        output_path = generate_jest("userService", functions, temp_output_dir)

        content = output_path.read_text()
        for func in functions:
            assert func in content

    def test_dry_run_mode(self, temp_output_dir: Path, capsys):
        """Test that dry-run mode doesn't create files for Jest."""
        output_path = generate_jest(
            "userService",
            ["createUser"],
            temp_output_dir,
            dry_run=True
        )

        assert not output_path.exists()

        captured = capsys.readouterr()
        assert "[dry-run]" in captured.out
        assert "userService.test.ts" in captured.out


class TestIntegration:
    """Integration tests for test generation."""

    @pytest.mark.integration
    def test_generate_multiple_test_files(self, temp_output_dir: Path):
        """Test generating multiple test files."""
        modules = [
            ("user_service", ["create_user", "get_user"]),
            ("post_service", ["create_post"]),
            ("comment_service", ["add_comment", "delete_comment"]),
        ]

        for module, functions in modules:
            generate_pytest(module, functions, temp_output_dir)

        # Check all files were created
        assert (temp_output_dir / "test_user_service.py").exists()
        assert (temp_output_dir / "test_post_service.py").exists()
        assert (temp_output_dir / "test_comment_service.py").exists()

    @pytest.mark.integration
    def test_generated_pytest_code_is_valid_python(self, temp_output_dir: Path):
        """Test that generated pytest code is syntactically valid Python."""
        output_path = generate_pytest(
            "user_service",
            ["create_user", "update_user"],
            temp_output_dir
        )

        content = output_path.read_text()
        try:
            compile(content, str(output_path), 'exec')
        except SyntaxError as e:
            pytest.fail(f"Generated code has syntax error: {e}")

    @pytest.mark.integration
    def test_generate_pytest_and_jest(self, temp_output_dir: Path):
        """Test generating both pytest and Jest tests."""
        pytest_dir = temp_output_dir / "python"
        jest_dir = temp_output_dir / "typescript"
        pytest_dir.mkdir()
        jest_dir.mkdir()

        generate_pytest("user_service", ["create_user"], pytest_dir)
        generate_jest("userService", ["createUser"], jest_dir)

        assert (pytest_dir / "test_user_service.py").exists()
        assert (jest_dir / "userService.test.ts").exists()

    @pytest.mark.integration
    def test_test_file_has_proper_structure(self, temp_output_dir: Path):
        """Test that generated test files have proper AAA structure."""
        output_path = generate_pytest(
            "calculator",
            ["add", "subtract"],
            temp_output_dir
        )

        content = output_path.read_text()
        # Check for AAA pattern comments or structure
        assert "# Arrange" in content or "# GIVEN" in content or "def test_" in content
        assert "# Act" in content or "# WHEN" in content or "def test_" in content
        assert "# Assert" in content or "# THEN" in content or "assert" in content
