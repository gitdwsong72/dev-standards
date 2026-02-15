#!/bin/bash

#######################################
# Python 코드 복잡도 분석
#
# 사용법:
#   ./scripts/check-complexity.sh              # 전체 분석
#   ./scripts/check-complexity.sh --ci         # CI 모드 (실패 시 exit 1)
#   ./scripts/check-complexity.sh --threshold 10  # CC 임계값 변경
#
# 필수 도구: radon (pip install radon)
#
# 측정 항목:
#   - Cyclomatic Complexity (CC): 코드 분기 복잡도
#     A(1-5), B(6-10), C(11-15), D(16-20), E(21-25), F(26+)
#   - Maintainability Index (MI): 유지보수성 지표
#     A(20-100), B(10-19), C(0-9)
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 기본 설정
CI_MODE=false
CC_THRESHOLD=15       # Cyclomatic Complexity 임계값
MI_THRESHOLD=20       # Maintainability Index 임계값 (권장)
PYTHON_DIRS=("scripts/generators")

while [[ $# -gt 0 ]]; do
    case $1 in
        --ci)
            CI_MODE=true
            shift
            ;;
        --threshold)
            CC_THRESHOLD="$2"
            shift 2
            ;;
        --mi-threshold)
            MI_THRESHOLD="$2"
            shift 2
            ;;
        --path)
            PYTHON_DIRS=("$2")
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--ci] [--threshold N] [--mi-threshold N] [--path DIR]"
            echo ""
            echo "Options:"
            echo "  --ci              CI mode (exit 1 on threshold violation)"
            echo "  --threshold N     CC threshold (default: 15)"
            echo "  --mi-threshold N  MI threshold (default: 20)"
            echo "  --path DIR        Python directory to analyze"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# radon 존재 확인
if ! python3 -c "import radon" &>/dev/null 2>&1; then
    echo -e "${RED}radon is not installed.${NC}"
    echo ""
    echo "Install: pip install radon"
    exit 1
fi

cc_violations=0
mi_warnings=0

for dir in "${PYTHON_DIRS[@]}"; do
    target="${PROJECT_ROOT}/${dir}"

    if [ ! -d "$target" ]; then
        echo -e "${YELLOW}SKIP: ${dir} (directory not found)${NC}"
        continue
    fi

    # --- Cyclomatic Complexity ---
    echo -e "${CYAN}=== Cyclomatic Complexity: ${dir} ===${NC}"
    echo -e "Threshold: CC < ${CC_THRESHOLD} (grades D, E, F will fail)"
    echo ""

    cc_output=$(python3 -m radon cc "$target" -s -a --exclude="test_*" -n C 2>&1)

    if [ -n "$cc_output" ]; then
        echo "$cc_output"
        echo ""

        # CC 임계값 초과 확인 (D 이상 = CC >= 16 기본)
        while IFS= read -r line; do
            if [[ "$line" =~ [[:space:]]-[[:space:]][CDEF][[:space:]]\(([0-9]+)\) ]]; then
                cc_value="${BASH_REMATCH[1]}"
                if [ "$cc_value" -ge "$CC_THRESHOLD" ]; then
                    ((cc_violations++))
                    echo -e "${RED}VIOLATION: CC=${cc_value} >= ${CC_THRESHOLD} in: ${line}${NC}"
                fi
            fi
        done <<< "$(python3 -m radon cc "$target" -s --exclude="test_*" 2>&1)"
    else
        echo -e "${GREEN}All functions have low complexity (A-B grade).${NC}"
    fi

    echo ""

    # --- Maintainability Index ---
    echo -e "${CYAN}=== Maintainability Index: ${dir} ===${NC}"
    echo -e "Recommended: MI >= ${MI_THRESHOLD}"
    echo ""

    mi_output=$(python3 -m radon mi "$target" -s 2>&1)
    echo "$mi_output"

    # MI 임계값 미달 확인
    while IFS= read -r line; do
        if [[ "$line" =~ [[:space:]]-[[:space:]][BC][[:space:]]\(([0-9]+(\.[0-9]+)?)\) ]]; then
            mi_value="${BASH_REMATCH[1]}"
            mi_int="${mi_value%%.*}"
            if [ "$mi_int" -lt "$MI_THRESHOLD" ]; then
                ((mi_warnings++))
                echo -e "${YELLOW}WARNING: MI=${mi_value} < ${MI_THRESHOLD} in: ${line}${NC}"
            fi
        fi
    done <<< "$mi_output"

    echo ""
done

# 결과 요약
echo "=============================="
echo "Complexity Analysis Summary"
echo "=============================="
echo "CC threshold: < ${CC_THRESHOLD}"
echo "CC violations: ${cc_violations}"
echo "MI threshold: >= ${MI_THRESHOLD} (recommended)"
echo "MI warnings: ${mi_warnings}"
echo "=============================="

if [ "$cc_violations" -gt 0 ]; then
    echo -e "${RED}FAIL: ${cc_violations} function(s) exceed CC threshold of ${CC_THRESHOLD}.${NC}"
    echo "Refactor complex functions to reduce cyclomatic complexity."
    exit 1
fi

if [ "$mi_warnings" -gt 0 ]; then
    echo -e "${YELLOW}WARN: ${mi_warnings} file(s) below recommended MI of ${MI_THRESHOLD}.${NC}"
    if [ "$CI_MODE" = true ]; then
        echo "MI warnings are non-blocking but should be addressed."
    fi
fi

echo -e "${GREEN}All complexity checks passed.${NC}"
exit 0
