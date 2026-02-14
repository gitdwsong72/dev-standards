#!/bin/bash

#######################################
# 필수 도구 체크
#######################################

# Load dependencies
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_LIB}/ui.sh"

check_prerequisites() {
    local missing=()

    # Frontend 필수 도구 체크
    if [[ "$PROJECT_TYPE" == "frontend" || "$PROJECT_TYPE" == "fullstack" ]]; then
        if ! command -v node &> /dev/null; then
            missing+=("node")
        fi
        if ! command -v pnpm &> /dev/null && ! command -v npm &> /dev/null; then
            missing+=("pnpm 또는 npm")
        fi
    fi

    # Backend 필수 도구 체크
    if [[ "$PROJECT_TYPE" == "backend" || "$PROJECT_TYPE" == "fullstack" ]]; then
        if ! command -v python3 &> /dev/null; then
            missing+=("python3")
        fi
        if ! command -v uv &> /dev/null; then
            echo ""
            print_warning "uv가 설치되어 있지 않습니다."
            echo ""
            echo "uv 설치 방법:"
            echo -e "  ${CYAN}# macOS / Linux${NC}"
            echo -e "  ${GREEN}curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
            echo ""
            echo -e "  ${CYAN}# Windows (PowerShell)${NC}"
            echo -e "  ${GREEN}powershell -ExecutionPolicy ByPass -c \"irm https://astral.sh/uv/install.ps1 | iex\"${NC}"
            echo ""
            echo -e "  ${CYAN}# pip로 설치${NC}"
            echo -e "  ${GREEN}pip install uv${NC}"
            echo ""
            echo "설치 후 터미널을 재시작하거나 다음 명령어를 실행하세요:"
            echo -e "  ${GREEN}source ~/.bashrc${NC}  또는  ${GREEN}source ~/.zshrc${NC}"
            echo ""
            missing+=("uv")
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "필수 도구가 설치되어 있지 않습니다: ${missing[*]}"
        exit 1
    fi
}
