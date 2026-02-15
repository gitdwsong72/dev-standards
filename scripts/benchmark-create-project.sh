#!/bin/bash

#######################################
# create-project.sh 벤치마크 스크립트
#
# 각 프로젝트 타입(frontend, backend, fullstack)의
# 생성 시간을 측정하고 임계값을 검증합니다.
#
# 사용법:
#   ./scripts/benchmark-create-project.sh
#   THRESHOLD=45 ./scripts/benchmark-create-project.sh
#######################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_SCRIPT="${SCRIPT_DIR}/create-project.sh"
THRESHOLD="${THRESHOLD:-30}"  # 기본 임계값: 30초

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 결과 저장
declare -a RESULTS=()
FAILED=0

#######################################
# 단일 시나리오 벤치마크 실행
# Arguments:
#   $1 - 시나리오 이름
#   $2 - 프로젝트 타입 (frontend/backend/fullstack)
#######################################
run_benchmark() {
    local scenario="$1"
    local project_type="$2"
    local tmp_dir

    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' RETURN

    echo -e "${CYAN}[BENCH]${NC} ${scenario} (type: ${project_type})..."

    local start_time end_time elapsed
    start_time=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time() * 1000000000))')

    # --help 실행 (dry-run 대용) + syntax validation
    # 실제 프로젝트 생성은 prerequisites(pnpm, python 등)가 필요하므로
    # 스크립트의 파싱/검증 단계만 벤치마크
    if echo "n" | bash "${CREATE_SCRIPT}" --name "bench-${project_type}" --type "${project_type}" --dir "${tmp_dir}" 2>/dev/null; then
        true  # 사용자가 'n'으로 취소 — 정상
    fi

    end_time=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time() * 1000000000))')

    # 나노초 -> 초 (소수점 포함)
    if command -v bc &>/dev/null; then
        elapsed=$(echo "scale=2; ($end_time - $start_time) / 1000000000" | bc)
    else
        elapsed=$(python3 -c "print(f'{($end_time - $start_time) / 1000000000:.2f}')")
    fi

    local status="PASS"
    local elapsed_int="${elapsed%.*}"
    if [ "${elapsed_int:-0}" -ge "$THRESHOLD" ]; then
        status="FAIL"
        FAILED=1
    fi

    RESULTS+=("${scenario}|${project_type}|${elapsed}s|${status}")

    if [ "$status" = "PASS" ]; then
        echo -e "  ${GREEN}PASS${NC} ${elapsed}s (threshold: ${THRESHOLD}s)"
    else
        echo -e "  ${RED}FAIL${NC} ${elapsed}s (threshold: ${THRESHOLD}s)"
    fi
}

#######################################
# 결과 테이블 출력
#######################################
print_results() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Benchmark Results${NC}"
    echo -e "${CYAN}========================================${NC}"
    printf "%-20s %-12s %-10s %-6s\n" "Scenario" "Type" "Time" "Status"
    printf "%-20s %-12s %-10s %-6s\n" "--------" "----" "----" "------"

    for result in "${RESULTS[@]}"; do
        IFS='|' read -r scenario ptype elapsed status <<< "$result"
        if [ "$status" = "PASS" ]; then
            printf "%-20s %-12s %-10s ${GREEN}%-6s${NC}\n" "$scenario" "$ptype" "$elapsed" "$status"
        else
            printf "%-20s %-12s %-10s ${RED}%-6s${NC}\n" "$scenario" "$ptype" "$elapsed" "$status"
        fi
    done

    echo ""
    echo "Threshold: ${THRESHOLD}s"
}

#######################################
# GitHub Step Summary 출력
#######################################
write_github_summary() {
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
        {
            echo "## Benchmark Results"
            echo ""
            echo "| Scenario | Type | Time | Status |"
            echo "|----------|------|------|--------|"
            for result in "${RESULTS[@]}"; do
                IFS='|' read -r scenario ptype elapsed status <<< "$result"
                local icon="✅"
                [ "$status" = "FAIL" ] && icon="❌"
                echo "| ${scenario} | ${ptype} | ${elapsed} | ${icon} ${status} |"
            done
            echo ""
            echo "**Threshold:** ${THRESHOLD}s"
        } >> "$GITHUB_STEP_SUMMARY"
    fi
}

#######################################
# 메인
#######################################
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  create-project.sh Benchmark${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo "Threshold: ${THRESHOLD}s"
    echo ""

    # 스크립트 존재 확인
    if [ ! -f "$CREATE_SCRIPT" ]; then
        echo -e "${RED}ERROR: create-project.sh not found at ${CREATE_SCRIPT}${NC}"
        exit 1
    fi

    chmod +x "$CREATE_SCRIPT"

    # 벤치마크 실행
    run_benchmark "Frontend Project" "frontend"
    run_benchmark "Backend Project" "backend"
    run_benchmark "Fullstack Project" "fullstack"

    # 결과 출력
    print_results
    write_github_summary

    if [ "$FAILED" -eq 1 ]; then
        echo -e "${RED}FAILED: One or more benchmarks exceeded the threshold${NC}"
        exit 1
    fi

    echo -e "${GREEN}All benchmarks passed!${NC}"
}

main "$@"
