#!/usr/bin/env python3
"""Generate React/Vue component boilerplate."""

import argparse
import sys
from pathlib import Path

from utils import load_template, check_overwrite


def validate_component_name(name: str) -> None:
    """Validate component name is PascalCase and prevent template injection.

    Args:
        name: Component name to validate

    Raises:
        ValueError: If name is invalid or contains injection patterns
    """
    if not name:
        raise ValueError("Component name cannot be empty")

    # Template injection defense: reject curly braces
    if '{' in name or '}' in name:
        raise ValueError(
            f"Invalid component name: {name}. "
            "Curly braces are not allowed (template injection risk)."
        )

    if not name[0].isupper():
        raise ValueError(
            f"Component name must be PascalCase: '{name}' should start with uppercase"
        )

    if not name.replace('_', '').isalnum():
        raise ValueError(f"Invalid component name: {name}. Use only alphanumeric characters.")


def _write_file(path: Path, content: str, *, force: bool = False, dry_run: bool = False) -> None:
    """Write content to a file with overwrite/dry-run support."""
    if dry_run:
        print(f"[dry-run] Would create {path}")
        return
    check_overwrite(path, force=force)
    path.write_text(content)
    print(f"Created {path}")


def generate_react(name: str, output_dir: str, with_test: bool = False, *, force: bool = False, dry_run: bool = False) -> list[Path]:
    """Generate React component files."""
    created_files = []

    path = Path(output_dir) / name
    if not dry_run:
        path.mkdir(parents=True, exist_ok=True)

    # Main component
    component_template = load_template("react_component.tsx.template")
    component_content = component_template.format(name=name, name_lower=name.lower())
    component_path = path / f"{name}.tsx"
    _write_file(component_path, component_content, force=force, dry_run=dry_run)
    created_files.append(component_path)

    # Test file
    if with_test:
        test_template = load_template("react_component.test.tsx.template")
        test_content = test_template.format(name=name, name_lower=name.lower())
        test_path = path / f"{name}.test.tsx"
        _write_file(test_path, test_content, force=force, dry_run=dry_run)
        created_files.append(test_path)

    # Index file
    index_template = load_template("react_index.ts.template")
    index_content = index_template.format(name=name)
    index_path = path / "index.ts"
    _write_file(index_path, index_content, force=force, dry_run=dry_run)
    created_files.append(index_path)

    return created_files


def generate_vue(name: str, output_dir: str, with_test: bool = False, *, force: bool = False, dry_run: bool = False) -> list[Path]:
    """Generate Vue component files."""
    created_files = []

    path = Path(output_dir)
    if not dry_run:
        path.mkdir(parents=True, exist_ok=True)

    # Main component
    component_template = load_template("vue_component.vue.template")
    component_content = component_template.format(name=name, name_lower=name.lower())
    component_path = path / f"{name}.vue"
    _write_file(component_path, component_content, force=force, dry_run=dry_run)
    created_files.append(component_path)

    # Test file
    if with_test:
        test_template = load_template("vue_component.test.ts.template")
        test_content = test_template.format(name=name, name_lower=name.lower())
        test_path = path / f"{name}.test.ts"
        _write_file(test_path, test_content, force=force, dry_run=dry_run)
        created_files.append(test_path)

    return created_files


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Generate component boilerplate',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s UserProfile --type react --with-test -o src/components
  %(prog)s NavBar --type vue --with-test -o src/components
  %(prog)s Button --type react -o src/components --dry-run
  %(prog)s Modal --type react --with-test --force
        """
    )
    parser.add_argument('name', help='Component name (PascalCase, e.g., "UserProfile")')
    parser.add_argument('--type', choices=['react', 'vue'], default='react',
                        help='Framework type (default: react)')
    parser.add_argument('--output', '-o', default='.', help='Output directory (default: current)')
    parser.add_argument('--with-test', action='store_true', help='Generate test file')
    parser.add_argument('--force', action='store_true', help='Overwrite existing files')
    parser.add_argument('--dry-run', action='store_true', help='Preview generated files without writing')

    args = parser.parse_args()

    try:
        # Validate input
        validate_component_name(args.name)

        # Generate based on type
        if args.type == 'react':
            generate_react(args.name, args.output, args.with_test, force=args.force, dry_run=args.dry_run)
        else:
            generate_vue(args.name, args.output, args.with_test, force=args.force, dry_run=args.dry_run)

        if not args.dry_run:
            print(f"\n{args.type.capitalize()} component '{args.name}' generated successfully!")
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
