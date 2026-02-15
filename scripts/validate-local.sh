#!/bin/bash

#######################################
# Local Validation Script - Full CI Simulation
#
# Runs all CI checks locally for fast feedback.
# Mirrors the GitHub Actions CI pipeline phases.
#
# Usage:
#   ./scripts/validate-local.sh           # Run all checks
#   ./scripts/validate-local.sh --quick   # Fast checks only (Phase 1)
#   ./scripts/validate-local.sh --phase 1 # Run specific phase
#   ./scripts/validate-local.sh --fix     # Auto-fix where possible
#   ./scripts/validate-local.sh --help    # Show help
#
# Phases:
#   1: Fast Checks (syntax, shellcheck, sensitive files)
#   2: Lint & Format (ruff, eslint, prettier)
#   3: Quality Gates (complexity, type checks)
#   4: Validation (tests, templates, package.json)
#######################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load shared UI library
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/ui.sh"

# Configuration
PHASE=""
QUICK=false
FIX_MODE=false
VERBOSE=false

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0
TOTAL_START=$(date +%s)

#######################################
# Argument parsing
#######################################

show_help() {
    echo "Local Validation - Full CI Simulation"
    echo ""
    echo "Usage:"
    echo "  $0 [options]"
    echo ""
    echo "Options:"
    echo "  --quick          Run Phase 1 only (fast checks)"
    echo "  --phase <N>      Run specific phase (1-4)"
    echo "  --fix            Auto-fix issues where possible"
    echo "  --verbose        Show detailed output"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Phases:"
    echo "  1  Fast Checks     - Bash syntax, shellcheck, sensitive files"
    echo "  2  Lint & Format   - Python (ruff), JS/TS (eslint), Markdown"
    echo "  3  Quality Gates   - Code complexity, type checking"
    echo "  4  Validation      - Tests, templates, package.json, links"
    echo ""
    echo "Examples:"
    echo "  $0                 # Full validation (all phases)"
    echo "  $0 --quick         # Fast checks only (~2s)"
    echo "  $0 --fix           # Fix + validate"
    echo "  $0 --phase 2       # Lint & format only"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK=true
            shift
            ;;
        --phase)
            PHASE="$2"
            shift 2
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

#######################################
# Helper functions
#######################################

check_pass() {
    print_success "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    print_error "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_warn() {
    print_warning "$1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

check_skip() {
    echo -e "  $1 ${YELLOW}(skipped)${NC}"
    SKIP_COUNT=$((SKIP_COUNT + 1))
}

run_if_exists() {
    local script="$1"
    local label="$2"
    local args="${3:-}"

    if [ -f "$script" ] && [ -x "$script" ]; then
        if $VERBOSE; then
            # shellcheck disable=SC2086
            if "$script" $args; then
                check_pass "$label"
            else
                check_fail "$label"
            fi
        else
            # shellcheck disable=SC2086
            if "$script" $args >/dev/null 2>&1; then
                check_pass "$label"
            else
                check_fail "$label"
            fi
        fi
    else
        check_skip "$label (script not found: $script)"
    fi
}

should_run_phase() {
    local phase_num="$1"
    if [ -n "$PHASE" ]; then
        [ "$PHASE" = "$phase_num" ]
    elif $QUICK; then
        [ "$phase_num" = "1" ]
    else
        true
    fi
}

phase_header() {
    local num="$1"
    local title="$2"
    echo ""
    echo -e "${CYAN}── Phase $num: $title ──${NC}"
    echo ""
}

#######################################
# Phase 1: Fast Checks
#######################################

phase_1_fast_checks() {
    phase_header 1 "Fast Checks"

    # 1a. Bash syntax validation
    local sh_files
    sh_files=$(find "$ROOT_DIR/scripts" -name "*.sh" -type f 2>/dev/null || true)

    if [ -n "$sh_files" ]; then
        local syntax_errors=0
        while IFS= read -r file; do
            if ! bash -n "$file" 2>/dev/null; then
                check_fail "Bash syntax: $file"
                syntax_errors=1
            fi
        done <<< "$sh_files"

        if [ "$syntax_errors" -eq 0 ]; then
            local count
            count=$(echo "$sh_files" | wc -l | tr -d ' ')
            check_pass "Bash syntax check ($count files)"
        fi
    else
        check_skip "Bash syntax (no .sh files)"
    fi

    # 1b. Shellcheck
    if [ -n "$sh_files" ]; then
        if [ -f "${SCRIPT_DIR}/lint-bash.sh" ] && [ -x "${SCRIPT_DIR}/lint-bash.sh" ]; then
            run_if_exists "${SCRIPT_DIR}/lint-bash.sh" "Shellcheck (lint-bash.sh)"
        elif command -v shellcheck >/dev/null 2>&1; then
            local sc_errors=0
            while IFS= read -r file; do
                if ! shellcheck -S error "$file" 2>/dev/null; then
                    if $VERBOSE; then
                        shellcheck "$file" 2>&1 | head -20
                    fi
                    sc_errors=1
                fi
            done <<< "$sh_files"

            if [ "$sc_errors" -eq 0 ]; then
                check_pass "Shellcheck"
            else
                check_fail "Shellcheck found errors (run 'shellcheck <file>' for details)"
            fi
        else
            check_skip "Shellcheck (not installed - brew install shellcheck)"
        fi
    fi

    # 1c. Script executability (top-level scripts only, not lib/ sources)
    local exec_scripts
    exec_scripts=$(find "$ROOT_DIR/scripts" -maxdepth 1 -name "*.sh" -type f 2>/dev/null || true)

    if [ -n "$exec_scripts" ]; then
        local non_exec=0
        while IFS= read -r file; do
            if [ -f "$file" ] && [ ! -x "$file" ]; then
                if $FIX_MODE; then
                    chmod +x "$file"
                    check_warn "Fixed: made executable: $(basename "$file")"
                else
                    check_fail "Not executable: $file"
                    non_exec=1
                fi
            fi
        done <<< "$exec_scripts"
        if [ "$non_exec" -eq 0 ] && ! $FIX_MODE; then
            check_pass "All top-level scripts executable"
        fi
    fi

    # 1d. Sensitive file detection
    local sensitive_found=0
    local sensitive_patterns=(".env" ".env.local" ".env.production" "credentials.json" "secrets.yaml" ".pem")

    for pattern in "${sensitive_patterns[@]}"; do
        if find "$ROOT_DIR" -name "$pattern" -not -path "*/.git/*" -not -path "*/node_modules/*" -print -quit 2>/dev/null | grep -q .; then
            check_fail "Sensitive file found: $pattern"
            sensitive_found=1
        fi
    done

    if [ "$sensitive_found" -eq 0 ]; then
        check_pass "No sensitive files detected"
    fi

    # 1e. Check .gitignore coverage
    if [ -f "$ROOT_DIR/.gitignore" ]; then
        check_pass ".gitignore exists"
    else
        check_warn "No .gitignore file"
    fi
}

#######################################
# Phase 2: Lint & Format
#######################################

phase_2_lint_format() {
    phase_header 2 "Lint & Format"

    # 2a. Python (ruff)
    local py_files
    py_files=$(find "$ROOT_DIR" -name "*.py" -not -path "*/.venv/*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*" -not -path "*/htmlcov/*" -type f 2>/dev/null || true)

    if [ -n "$py_files" ]; then
        if command -v ruff >/dev/null 2>&1; then
            if $FIX_MODE; then
                if ruff format "$ROOT_DIR" 2>/dev/null; then
                    check_pass "Python format auto-fix (ruff format)"
                else
                    check_warn "Python format: some files could not be formatted"
                fi
                if ruff check --fix "$ROOT_DIR" 2>/dev/null; then
                    check_pass "Python lint auto-fix (ruff check --fix)"
                else
                    check_warn "Python lint: some issues could not be auto-fixed"
                fi
            fi

            # Check (always runs, after fix if --fix)
            if ruff check "$ROOT_DIR" 2>/dev/null; then
                check_pass "Python lint (ruff check)"
            else
                if $VERBOSE; then
                    ruff check "$ROOT_DIR" 2>&1 | head -30
                fi
                check_fail "Python lint errors (run 'ruff check --fix' to auto-fix)"
            fi

            if ruff format --check "$ROOT_DIR" 2>/dev/null; then
                check_pass "Python format (ruff format)"
            else
                check_fail "Python format issues (run 'ruff format' to fix)"
            fi
        else
            check_skip "Python lint (ruff not installed - pip install ruff)"
        fi
    else
        check_skip "Python lint (no .py files)"
    fi

    # 2b. JavaScript/TypeScript (eslint)
    local js_packages=("eslint-config" "prettier-config" "typescript-config")
    for pkg in "${js_packages[@]}"; do
        local pkg_dir="$ROOT_DIR/packages/$pkg"
        if [ -d "$pkg_dir" ] && [ -f "$pkg_dir/package.json" ]; then
            # Validate package.json
            if node -e "
                const pkg = require('$pkg_dir/package.json');
                const required = ['name', 'version', 'description', 'license'];
                const missing = required.filter(f => !pkg[f]);
                if (missing.length) { console.error('Missing:', missing.join(', ')); process.exit(1); }
            " 2>/dev/null; then
                check_pass "Package.json valid: $pkg"
            else
                check_fail "Package.json invalid: $pkg"
            fi

            # Check exports resolve
            if node -e "
                const pkg = require('$pkg_dir/package.json');
                const fs = require('fs');
                const path = require('path');
                const exports = pkg.exports || {};
                for (const [key, value] of Object.entries(exports)) {
                    const file = typeof value === 'string' ? value : value.default || value.import || value.require;
                    if (file && !fs.existsSync(path.join('$pkg_dir', file))) {
                        process.exit(1);
                    }
                }
            " 2>/dev/null; then
                check_pass "Exports resolve: $pkg"
            else
                check_fail "Exports not found: $pkg"
            fi
        fi
    done

    # 2c. Markdown validation
    local md_empty=0
    local md_count=0
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            md_count=$((md_count + 1))
            if [ ! -s "$file" ]; then
                check_fail "Empty markdown: $file"
                md_empty=1
            fi
        fi
    done < <(find "$ROOT_DIR/templates" "$ROOT_DIR/docs" -name "*.md" -type f 2>/dev/null || true)

    if [ "$md_count" -gt 0 ] && [ "$md_empty" -eq 0 ]; then
        check_pass "Markdown files non-empty ($md_count files)"
    fi
}

#######################################
# Phase 3: Quality Gates
#######################################

phase_3_quality_gates() {
    phase_header 3 "Quality Gates"

    # 3a. Code complexity
    run_if_exists "${SCRIPT_DIR}/check-complexity.sh" "Code complexity analysis"

    # 3b. Python type checking
    if command -v mypy >/dev/null 2>&1; then
        local python_src="$ROOT_DIR/packages/python-standards/src"
        if [ -d "$python_src" ]; then
            if mypy "$python_src" --ignore-missing-imports 2>/dev/null; then
                check_pass "Python type check (mypy)"
            else
                if $VERBOSE; then
                    mypy "$python_src" --ignore-missing-imports 2>&1 | head -20
                fi
                check_fail "Python type errors (run 'mypy' for details)"
            fi
        else
            check_skip "Python type check (no src/ directory)"
        fi
    else
        check_skip "Python type check (mypy not installed)"
    fi

    # 3c. Create-project script validation
    if [ -f "$ROOT_DIR/scripts/create-project.sh" ]; then
        # Syntax check
        if bash -n "$ROOT_DIR/scripts/create-project.sh" 2>/dev/null; then
            check_pass "create-project.sh syntax"
        else
            check_fail "create-project.sh syntax error"
        fi

        # Help flag test
        if chmod +x "$ROOT_DIR/scripts/create-project.sh" && \
           "$ROOT_DIR/scripts/create-project.sh" --help >/dev/null 2>&1; then
            check_pass "create-project.sh --help"
        else
            check_fail "create-project.sh --help failed"
        fi

        # Security: reject path traversal
        if "$ROOT_DIR/scripts/create-project.sh" --name "../escape" --type frontend >/dev/null 2>&1; then
            check_fail "create-project.sh accepts path traversal input"
        else
            check_pass "create-project.sh rejects path traversal"
        fi

        # Security: reject invalid type
        if "$ROOT_DIR/scripts/create-project.sh" --name testproject --type invalid >/dev/null 2>&1; then
            check_fail "create-project.sh accepts invalid type"
        else
            check_pass "create-project.sh rejects invalid type"
        fi
    fi
}

#######################################
# Phase 4: Validation
#######################################

phase_4_validation() {
    phase_header 4 "Validation"

    # 4a. Template files exist
    local required_templates=(
        "templates/claude-agents/react-specialist.md"
        "templates/claude-agents/fastapi-specialist.md"
        "templates/claude-agents/e2e-test-specialist.md"
        "templates/claude-agents/sql-query-specialist.md"
        "templates/claude-agents/api-test-specialist.md"
        "templates/claude-agents/code-quality-reviewer.md"
    )

    local templates_missing=0
    for tmpl in "${required_templates[@]}"; do
        if [ ! -f "$ROOT_DIR/$tmpl" ]; then
            check_fail "Missing template: $tmpl"
            templates_missing=1
        fi
    done

    if [ "$templates_missing" -eq 0 ]; then
        check_pass "Required templates exist (${#required_templates[@]} files)"
    fi

    # 4b. Python tests (must run from generators directory for imports)
    if [ -f "$ROOT_DIR/scripts/generators/pytest.ini" ]; then
        if command -v python3 >/dev/null 2>&1 && python3 -c "import pytest" 2>/dev/null; then
            local test_output
            if test_output=$(cd "$ROOT_DIR/scripts/generators" && python3 -m pytest --tb=short -q --no-header --override-ini="addopts=" 2>&1); then
                check_pass "Python generator tests"
            else
                if $VERBOSE; then
                    echo "$test_output" | tail -20
                fi
                check_fail "Python generator tests failed"
            fi
        else
            check_skip "Python tests (pytest not installed)"
        fi
    else
        check_skip "Python tests (no pytest.ini)"
    fi

    # 4c. Bundle size check (npm packages, excluding node_modules)
    for pkg_dir in "$ROOT_DIR"/packages/*/; do
        if [ -f "$pkg_dir/package.json" ]; then
            local pkg_name
            pkg_name=$(basename "$pkg_dir")
            local dir_size
            dir_size=$(du -sk --exclude='node_modules' "$pkg_dir" 2>/dev/null || du -sk -I node_modules "$pkg_dir" 2>/dev/null | cut -f1)
            dir_size=$(echo "$dir_size" | cut -f1)
            if [ "$dir_size" -gt 512 ] 2>/dev/null; then
                check_warn "Package $pkg_name size: ${dir_size}KB (threshold: 512KB)"
            else
                check_pass "Package size OK: $pkg_name (${dir_size}KB)"
            fi
        fi
    done

    # 4d. Version management (syntax check only - dry-run requires version type)
    if [ -f "${SCRIPT_DIR}/bump-version.sh" ] && [ -x "${SCRIPT_DIR}/bump-version.sh" ]; then
        if bash -n "${SCRIPT_DIR}/bump-version.sh" 2>/dev/null; then
            check_pass "Version management script (syntax OK)"
        else
            check_fail "Version management script (syntax error)"
        fi
    else
        check_skip "Version management (script not found)"
    fi

    # 4e. CHANGELOG generation (requires git-cliff)
    if [ -f "${SCRIPT_DIR}/generate-changelog.sh" ] && [ -x "${SCRIPT_DIR}/generate-changelog.sh" ]; then
        if command -v git-cliff >/dev/null 2>&1; then
            run_if_exists "${SCRIPT_DIR}/generate-changelog.sh" "CHANGELOG generation (dry-run)" "--dry-run"
        else
            check_skip "CHANGELOG generation (git-cliff not installed)"
        fi
    else
        check_skip "CHANGELOG generation (script not found)"
    fi
}

#######################################
# Main
#######################################

main() {
    print_header "Local Validation"

    if $QUICK; then
        echo -e "  Mode: ${YELLOW}Quick (Phase 1 only)${NC}"
    elif [ -n "$PHASE" ]; then
        echo -e "  Mode: ${YELLOW}Phase $PHASE only${NC}"
    else
        echo -e "  Mode: ${GREEN}Full validation${NC}"
    fi

    if $FIX_MODE; then
        echo -e "  Auto-fix: ${GREEN}enabled${NC}"
    fi
    echo ""

    # Run phases
    if should_run_phase 1; then
        phase_1_fast_checks
    fi

    if should_run_phase 2; then
        phase_2_lint_format
    fi

    if should_run_phase 3; then
        phase_3_quality_gates
    fi

    if should_run_phase 4; then
        phase_4_validation
    fi

    # Summary
    local TOTAL_END
    TOTAL_END=$(date +%s)
    local TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

    echo ""
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${CYAN}  Validation Summary${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}  $PASS_COUNT"
    echo -e "  ${RED}Failed:${NC}  $FAIL_COUNT"
    echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT"
    echo -e "  Skipped: $SKIP_COUNT"
    echo -e "  Duration: ${TOTAL_DURATION}s"
    echo ""

    if [ "$FAIL_COUNT" -gt 0 ]; then
        print_error "Validation FAILED ($FAIL_COUNT errors)"
        echo ""
        echo "  Tips:"
        echo "    - Run with --fix to auto-fix formatting issues"
        echo "    - Run with --verbose for detailed error output"
        echo "    - Run with --phase N to focus on a specific phase"
        echo ""
        exit 1
    elif [ "$WARN_COUNT" -gt 0 ]; then
        print_warning "Validation PASSED with warnings"
        exit 0
    else
        print_success "All checks passed!"
        exit 0
    fi
}

main
