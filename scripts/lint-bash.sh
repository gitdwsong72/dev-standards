#!/bin/bash

#######################################
# Bash 스크립트 Shellcheck 린트
#
# 사용법:
#   ./scripts/lint-bash.sh          # 전체 스크립트 검사
#   ./scripts/lint-bash.sh --fix    # 수정 제안 포함 출력
#   ./scripts/lint-bash.sh --ci     # CI 모드 (포맷 출력)
#
# 필수 도구: shellcheck
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 검사 대상 스크립트
BASH_SCRIPTS=(
    "scripts/create-project.sh"
    "scripts/lint-bash.sh"
    "scripts/check-complexity.sh"
    "scripts/bump-version.sh"
    "scripts/generate-changelog.sh"
    "scripts/validate-local.sh"
    "scripts/benchmark-create-project.sh"
    "scripts/lib/colors.sh"
    "scripts/lib/ui.sh"
    "scripts/lib/validators.sh"
    "scripts/lib/prerequisites.sh"
    "scripts/lib/commitlint.sh"
    "scripts/lib/templates-frontend.sh"
    "scripts/lib/templates-backend.sh"
    "scripts/lib/templates-fullstack.sh"
)

# 모드 설정
CI_MODE=false
FIX_MODE=false
SEVERITY="warning"

while [[ $# -gt 0 ]]; do
    case $1 in
        --ci)
            CI_MODE=true
            shift
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --severity)
            SEVERITY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--ci] [--fix] [--severity error|warning|info]"
            echo ""
            echo "Options:"
            echo "  --ci         CI mode (GitHub Actions format)"
            echo "  --fix        Show fix suggestions"
            echo "  --severity   Minimum severity (default: warning)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check shellcheck is installed
if ! command -v shellcheck &>/dev/null; then
    echo -e "${RED}shellcheck is not installed.${NC}"
    echo ""
    echo "Install:"
    echo "  macOS:  brew install shellcheck"
    echo "  Ubuntu: apt-get install shellcheck"
    echo "  CI:     uses: ludeeus/action-shellcheck@master"
    exit 1
fi

echo "Shellcheck $(shellcheck --version | grep '^version:' | awk '{print $2}')"
echo ""

# 검사 실행
errors=0
checked=0
skipped=0

for script in "${BASH_SCRIPTS[@]}"; do
    filepath="${PROJECT_ROOT}/${script}"

    if [ ! -f "$filepath" ]; then
        echo -e "${YELLOW}SKIP: ${script} (file not found)${NC}"
        ((skipped++))
        continue
    fi

    ((checked++))

    # Configure lint options
    # SC1091: cannot follow dynamic source paths
    # SC2034: library variables used in sourced files
    SC_ARGS=(
        --severity="$SEVERITY"
        "--exclude=SC1091,SC2034"
        --shell=bash
    )

    if [ "$CI_MODE" = true ]; then
        SC_ARGS+=(--format=gcc)
    fi

    if [ "$FIX_MODE" = true ]; then
        SC_ARGS+=(--format=diff)
    fi

    if shellcheck "${SC_ARGS[@]}" "$filepath" 2>&1; then
        if [ "$CI_MODE" = false ] && [ "$FIX_MODE" = false ]; then
            echo -e "${GREEN}PASS: ${script}${NC}"
        fi
    else
        echo -e "${RED}FAIL: ${script}${NC}"
        ((errors++))
    fi
done

# 결과 요약
echo ""
echo "=============================="
echo "Results: ${checked} checked, ${errors} failed, ${skipped} skipped"
echo "=============================="

if [ "$errors" -gt 0 ]; then
    echo -e "${RED}Shellcheck found issues in ${errors} file(s).${NC}"
    exit 1
fi

echo -e "${GREEN}All scripts passed shellcheck.${NC}"
exit 0
