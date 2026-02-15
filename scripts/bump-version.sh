#!/bin/bash
set -euo pipefail

#######################################
# Version Bump Script
# Atomically updates all package versions
# (npm + Python) with CHANGELOG generation
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/ui.sh"

# Package paths
NPM_PACKAGES=(
    "packages/eslint-config"
    "packages/prettier-config"
    "packages/typescript-config"
)
PYTHON_PACKAGE="packages/python-standards"

# Defaults
DRY_RUN=false
VERSION_TYPE=""
SKIP_TAG=false
SKIP_CHANGELOG=false

#######################################
# Usage
#######################################
usage() {
    cat <<EOF
Usage: $(basename "$0") <patch|minor|major> [options]

Bump version for all packages atomically.

Arguments:
  patch               Bump patch version (1.0.0 -> 1.0.1)
  minor               Bump minor version (1.0.0 -> 1.1.0)
  major               Bump major version (1.0.0 -> 2.0.0)

Options:
  --dry-run           Show what would change without modifying files
  --skip-tag          Skip Git tag creation
  --skip-changelog    Skip CHANGELOG generation
  -h, --help          Show this help message

Examples:
  $(basename "$0") patch
  $(basename "$0") minor --dry-run
  $(basename "$0") major --skip-tag
EOF
    exit 0
}

#######################################
# Parse arguments
#######################################
parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            patch|minor|major)
                VERSION_TYPE="$1"
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --skip-tag)
                SKIP_TAG=true
                ;;
            --skip-changelog)
                SKIP_CHANGELOG=true
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown argument: $1"
                usage
                ;;
        esac
        shift
    done

    if [[ -z "$VERSION_TYPE" ]]; then
        print_error "Version type (patch|minor|major) is required"
        exit 1
    fi
}

#######################################
# Get current version from eslint-config
# (source of truth — all packages share version)
#######################################
get_current_version() {
    local pkg_json="${ROOT_DIR}/${NPM_PACKAGES[0]}/package.json"
    if command -v node &>/dev/null; then
        node -p "require('${pkg_json}').version"
    else
        grep '"version"' "$pkg_json" | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/'
    fi
}

#######################################
# Calculate new version
#######################################
calc_new_version() {
    local current="$1"
    local type="$2"

    IFS='.' read -r major minor patch <<< "$current"

    case "$type" in
        patch) patch=$((patch + 1)) ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        major) major=$((major + 1)); minor=0; patch=0 ;;
    esac

    echo "${major}.${minor}.${patch}"
}

#######################################
# Verify all packages have same version
#######################################
verify_version_sync() {
    local expected="$1"

    for pkg_dir in "${NPM_PACKAGES[@]}"; do
        local pkg_json="${ROOT_DIR}/${pkg_dir}/package.json"
        local version
        if command -v node &>/dev/null; then
            version=$(node -p "require('${pkg_json}').version")
        else
            version=$(grep '"version"' "$pkg_json" | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')
        fi
        if [[ "$version" != "$expected" ]]; then
            print_error "${pkg_dir} has version ${version}, expected ${expected}"
            return 1
        fi
    done

    # Check Python package
    local py_version
    py_version=$(grep '^version' "${ROOT_DIR}/${PYTHON_PACKAGE}/pyproject.toml" | sed 's/.*"\([^"]*\)".*/\1/')
    if [[ "$py_version" != "$expected" ]]; then
        print_error "${PYTHON_PACKAGE} has version ${py_version}, expected ${expected}"
        return 1
    fi

    print_success "All packages at version ${expected}"
}

#######################################
# Update npm package.json version
#######################################
update_npm_version() {
    local pkg_dir="$1"
    local new_version="$2"
    local pkg_json="${ROOT_DIR}/${pkg_dir}/package.json"

    if [[ "$DRY_RUN" == true ]]; then
        print_step "[DRY-RUN] Would update ${pkg_dir}/package.json -> ${new_version}"
        return
    fi

    # Use node for reliable JSON editing
    if command -v node &>/dev/null; then
        node -e "
            const fs = require('fs');
            const pkg = JSON.parse(fs.readFileSync('${pkg_json}', 'utf8'));
            pkg.version = '${new_version}';
            fs.writeFileSync('${pkg_json}', JSON.stringify(pkg, null, 2) + '\n');
        "
    else
        # Fallback: sed-based replacement
        sed -i.bak "s/\"version\": *\"[^\"]*\"/\"version\": \"${new_version}\"/" "$pkg_json"
        rm -f "${pkg_json}.bak"
    fi

    print_success "Updated ${pkg_dir}/package.json -> ${new_version}"
}

#######################################
# Update Python pyproject.toml version
#######################################
update_python_version() {
    local new_version="$1"
    local pyproject="${ROOT_DIR}/${PYTHON_PACKAGE}/pyproject.toml"

    if [[ "$DRY_RUN" == true ]]; then
        print_step "[DRY-RUN] Would update ${PYTHON_PACKAGE}/pyproject.toml -> ${new_version}"
        return
    fi

    sed -i.bak "s/^version = \"[^\"]*\"/version = \"${new_version}\"/" "$pyproject"
    rm -f "${pyproject}.bak"

    print_success "Updated ${PYTHON_PACKAGE}/pyproject.toml -> ${new_version}"
}

#######################################
# Generate CHANGELOG entry
#######################################
generate_changelog() {
    local new_version="$1"
    local today
    today=$(date +%Y-%m-%d)

    if [[ "$DRY_RUN" == true ]]; then
        print_step "[DRY-RUN] Would generate CHANGELOG entries for v${new_version}"
        return
    fi

    # Collect commits since last tag
    local last_tag
    last_tag=$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || echo "")

    local log_range
    if [[ -n "$last_tag" ]]; then
        log_range="${last_tag}..HEAD"
    else
        log_range="HEAD"
    fi

    # Categorize commits
    local features="" fixes="" refactors="" others=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        case "$line" in
            feat*) features="${features}\n- ${line}" ;;
            fix*)  fixes="${fixes}\n- ${line}" ;;
            refactor*) refactors="${refactors}\n- ${line}" ;;
            *)     others="${others}\n- ${line}" ;;
        esac
    done < <(git -C "$ROOT_DIR" log --pretty=format:"%s" "$log_range" 2>/dev/null || true)

    # Build changelog entry
    local entry="## [${new_version}] - ${today}\n"

    if [[ -n "$features" ]]; then
        entry="${entry}\n### Added\n${features}\n"
    fi
    if [[ -n "$fixes" ]]; then
        entry="${entry}\n### Fixed\n${fixes}\n"
    fi
    if [[ -n "$refactors" ]]; then
        entry="${entry}\n### Changed\n${refactors}\n"
    fi
    if [[ -n "$others" ]]; then
        entry="${entry}\n### Other\n${others}\n"
    fi

    # Update each CHANGELOG.md
    for pkg_dir in "${NPM_PACKAGES[@]}"; do
        local changelog="${ROOT_DIR}/${pkg_dir}/CHANGELOG.md"
        if [[ -f "$changelog" ]]; then
            # Insert after the header line (after "---")
            local tmp
            tmp=$(mktemp)
            awk -v entry="$(echo -e "$entry")" '
                /^---$/ { print; print ""; print entry; next }
                { print }
            ' "$changelog" > "$tmp"
            mv "$tmp" "$changelog"
            print_success "Updated ${pkg_dir}/CHANGELOG.md"
        fi
    done

    # Create root CHANGELOG.md if it doesn't exist
    local root_changelog="${ROOT_DIR}/CHANGELOG.md"
    if [[ ! -f "$root_changelog" ]]; then
        cat > "$root_changelog" <<HEADER
# Changelog - dev-standards

All notable changes to this project will be documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

---

HEADER
    fi

    # Insert into root CHANGELOG
    local tmp
    tmp=$(mktemp)
    awk -v entry="$(echo -e "$entry")" '
        /^---$/ { print; print ""; print entry; next }
        { print }
    ' "$root_changelog" > "$tmp"
    mv "$tmp" "$root_changelog"
    print_success "Updated CHANGELOG.md (root)"
}

#######################################
# Create Git tag
#######################################
create_git_tag() {
    local new_version="$1"
    local tag="v${new_version}"

    if [[ "$DRY_RUN" == true ]]; then
        print_step "[DRY-RUN] Would create Git tag: ${tag}"
        return
    fi

    # Stage all version changes
    git -C "$ROOT_DIR" add \
        "${NPM_PACKAGES[@]/#/}" \
        "$PYTHON_PACKAGE/pyproject.toml"

    if [[ "$SKIP_CHANGELOG" != true ]]; then
        git -C "$ROOT_DIR" add -A "*.md" 2>/dev/null || true
    fi

    git -C "$ROOT_DIR" commit -m "chore(release): v${new_version}

Bump all package versions to ${new_version}"

    git -C "$ROOT_DIR" tag -a "$tag" -m "Release ${tag}"

    print_success "Created commit and tag: ${tag}"
    print_step "Run 'git push origin main --tags' to publish"
}

#######################################
# Rollback on failure
#######################################
rollback() {
    print_error "Version bump failed — rolling back changes"
    git -C "$ROOT_DIR" checkout -- . 2>/dev/null || true
    exit 1
}

#######################################
# Main
#######################################
main() {
    parse_args "$@"

    print_header "Version Bump (${VERSION_TYPE})"

    # Verify git working tree is clean (skip in dry-run)
    if [[ "$DRY_RUN" != true && "$SKIP_TAG" != true ]]; then
        if ! git -C "$ROOT_DIR" diff --quiet 2>/dev/null || ! git -C "$ROOT_DIR" diff --cached --quiet 2>/dev/null; then
            print_error "Working tree has uncommitted changes. Commit or stash them first."
            exit 1
        fi
    fi

    # Get current and new version
    local current_version new_version
    current_version=$(get_current_version)
    new_version=$(calc_new_version "$current_version" "$VERSION_TYPE")

    print_step "Current version: ${current_version}"
    print_step "New version:     ${new_version}"
    echo ""

    # Verify all packages are in sync
    verify_version_sync "$current_version" || exit 1

    # Set up rollback trap (only for real runs)
    if [[ "$DRY_RUN" != true ]]; then
        trap rollback ERR
    fi

    # Update npm packages
    for pkg_dir in "${NPM_PACKAGES[@]}"; do
        update_npm_version "$pkg_dir" "$new_version"
    done

    # Update Python package
    update_python_version "$new_version"

    # Generate CHANGELOG
    if [[ "$SKIP_CHANGELOG" != true ]]; then
        generate_changelog "$new_version"
    fi

    # Create Git tag
    if [[ "$SKIP_TAG" != true ]]; then
        create_git_tag "$new_version"
    fi

    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        print_header "Dry Run Complete"
        print_step "No files were modified"
    else
        print_header "Version Bump Complete"
        print_success "All packages updated to v${new_version}"
    fi
}

main "$@"
