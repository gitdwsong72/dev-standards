#!/usr/bin/env python3
"""Generate test boilerplate for Python (pytest) or TypeScript (Jest)."""

import argparse
import re
import sys
from pathlib import Path

from utils import load_template, to_pascal_case, check_overwrite


def validate_module_name(module: str) -> None:
    """Validate module name and prevent template injection.

    Args:
        module: Module name to validate

    Raises:
        ValueError: If module name is invalid or contains injection patterns
    """
    if not module:
        raise ValueError("Module name cannot be empty")

    # Template injection defense: reject curly braces
    if '{' in module or '}' in module:
        raise ValueError(
            f"Invalid module name: {module}. "
            "Curly braces are not allowed (template injection risk)."
        )

    if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', module):
        raise ValueError(f"Invalid module name: {module}. Use valid identifier format.")


def validate_function_names(functions: list[str]) -> None:
    """Validate function names and prevent template injection.

    Args:
        functions: List of function names to validate

    Raises:
        ValueError: If any function name is invalid or contains injection patterns
    """
    if not functions:
        raise ValueError("At least one function name is required")

    for func in functions:
        # Template injection defense: reject curly braces
        if '{' in func or '}' in func:
            raise ValueError(
                f"Invalid function name: {func}. "
                "Curly braces are not allowed (template injection risk)."
            )

        if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', func):
            raise ValueError(f"Invalid function name: {func}. Use valid identifier format.")


def generate_pytest(module: str, functions: list[str], output_dir: Path, *, force: bool = False, dry_run: bool = False) -> Path:
    """Generate pytest test file."""
    class_name = to_pascal_case(module)

    # Load templates
    main_template = load_template("pytest_test.py.template")
    method_template = load_template("pytest_method.py.template")

    # Generate test methods
    test_methods = '\n'.join(
        method_template.format(func_name=func)
        for func in functions
    )

    content = main_template.format(
        module=module,
        functions=', '.join(functions),
        class_name=class_name,
        test_methods=test_methods
    )

    filename = f"test_{module}.py"
    output_path = output_dir / filename

    if dry_run:
        print(f"[dry-run] Would create {output_path}")
        print(content)
        return output_path

    check_overwrite(output_path, force=force)
    output_path.write_text(content)
    return output_path


def generate_jest(module: str, functions: list[str], output_dir: Path, *, force: bool = False, dry_run: bool = False) -> Path:
    """Generate Jest test file."""
    class_name = to_pascal_case(module)

    # Load templates
    main_template = load_template("jest_test.ts.template")
    case_template = load_template("jest_case.ts.template")

    # Generate test cases
    test_cases = '\n'.join(
        case_template.format(func_name=func)
        for func in functions
    )

    content = main_template.format(
        module=module,
        functions=', '.join(functions),
        class_name=class_name,
        test_cases=test_cases
    )

    filename = f"{module}.test.ts"
    output_path = output_dir / filename

    if dry_run:
        print(f"[dry-run] Would create {output_path}")
        print(content)
        return output_path

    check_overwrite(output_path, force=force)
    output_path.write_text(content)
    return output_path


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Generate test boilerplate',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s user_service create_user get_user --type pytest -o tests
  %(prog)s userService createUser getUser --type jest -o __tests__
  %(prog)s auth_utils validate_token refresh_token --type pytest --dry-run
  %(prog)s user_service create_user --type pytest --force
        """
    )
    parser.add_argument('module', help='Module name to test')
    parser.add_argument('functions', nargs='+', help='Function names to test')
    parser.add_argument('--type', choices=['pytest', 'jest'], default='pytest',
                        help='Test framework (default: pytest)')
    parser.add_argument('--output', '-o', default='.', help='Output directory (default: current)')
    parser.add_argument('--force', action='store_true', help='Overwrite existing files')
    parser.add_argument('--dry-run', action='store_true', help='Preview generated code without writing files')

    args = parser.parse_args()

    try:
        # Validate input
        validate_module_name(args.module)
        validate_function_names(args.functions)

        # Create output directory
        output_dir = Path(args.output)
        if not args.dry_run:
            output_dir.mkdir(parents=True, exist_ok=True)

        # Generate based on type
        if args.type == 'pytest':
            output_path = generate_pytest(args.module, args.functions, output_dir, force=args.force, dry_run=args.dry_run)
        else:
            output_path = generate_jest(args.module, args.functions, output_dir, force=args.force, dry_run=args.dry_run)

        if not args.dry_run:
            print(f"Created {output_path}")
            print(f"\n{args.type.capitalize()} tests for '{args.module}' generated successfully!")
        return 0

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except FileExistsError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except ValueError as e:
        print(f"Validation error: {e}", file=sys.stderr)
        return 1
    except PermissionError as e:
        print(f"Permission denied: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
