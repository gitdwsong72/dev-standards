#!/usr/bin/env python3
"""Generate API endpoint boilerplate for Python (FastAPI) or TypeScript (Express)."""

import argparse
import sys
from pathlib import Path

from utils import load_template, to_pascal_case, to_singular, check_overwrite


def validate_resource_name(resource: str) -> None:
    """Validate resource name and prevent template injection attacks.

    Args:
        resource: Resource name to validate

    Raises:
        ValueError: If resource name is invalid or contains injection patterns
    """
    if not resource:
        raise ValueError("Resource name cannot be empty")

    # Template injection defense: reject curly braces
    if '{' in resource or '}' in resource:
        raise ValueError(
            f"Invalid resource name: {resource}. "
            "Curly braces are not allowed (template injection risk)."
        )

    if not resource.replace('_', '').replace('-', '').isalnum():
        raise ValueError(
            f"Invalid resource name: {resource}. "
            "Use only alphanumeric, hyphens, or underscores."
        )


def generate_fastapi(resource: str, output_dir: Path, *, force: bool = False, dry_run: bool = False) -> Path:
    """Generate FastAPI router."""
    template = load_template("fastapi_router.py.template")

    resource_singular = to_singular(resource)
    model = to_pascal_case(resource_singular)

    content = template.format(
        resource=resource,
        resource_singular=resource_singular,
        model=model
    )

    filename = f"{resource}_router.py"
    output_path = output_dir / filename

    if dry_run:
        print(f"[dry-run] Would create {output_path}")
        print(content)
        return output_path

    check_overwrite(output_path, force=force)
    output_path.write_text(content)
    return output_path


def generate_express(resource: str, output_dir: Path, *, force: bool = False, dry_run: bool = False) -> Path:
    """Generate Express router."""
    template = load_template("express_router.ts.template")

    resource_singular = to_singular(resource)
    model = to_pascal_case(resource_singular)

    content = template.format(
        resource=resource,
        resource_singular=resource_singular,
        model=model
    )

    filename = f"{resource}.routes.ts"
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
        description='Generate API endpoint boilerplate',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s users --type fastapi -o src/routers
  %(prog)s posts --type express -o src/routes
  %(prog)s categories --type fastapi --dry-run
  %(prog)s users --type express --force
        """
    )
    parser.add_argument('resource', help='Resource name (plural, e.g., "users", "posts")')
    parser.add_argument('--type', choices=['fastapi', 'express'], default='fastapi',
                        help='Framework type (default: fastapi)')
    parser.add_argument('--output', '-o', default='.', help='Output directory (default: current)')
    parser.add_argument('--force', action='store_true', help='Overwrite existing files')
    parser.add_argument('--dry-run', action='store_true', help='Preview generated code without writing files')

    args = parser.parse_args()

    try:
        # Validate input
        resource = args.resource.lower()
        validate_resource_name(resource)

        # Create output directory
        output_dir = Path(args.output)
        if not args.dry_run:
            output_dir.mkdir(parents=True, exist_ok=True)

        # Generate based on type
        if args.type == 'fastapi':
            output_path = generate_fastapi(resource, output_dir, force=args.force, dry_run=args.dry_run)
        else:
            output_path = generate_express(resource, output_dir, force=args.force, dry_run=args.dry_run)

        if not args.dry_run:
            print(f"Created {output_path}")
            print(f"\n{args.type.capitalize()} API for '{resource}' generated successfully!")
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
