#!/bin/bash

#######################################
# 신규 프로젝트 생성 스크립트
#
# 사용법:
#   ./create-project.sh
#   ./create-project.sh --name my-project --type fullstack
#   ./create-project.sh -n my-app -t frontend
#   ./create-project.sh -n my-project -t fullstack -f my-frontend -b my-backend
#
# 옵션:
#   -n, --name      프로젝트 이름 (필수)
#   -t, --type      프로젝트 타입: frontend, backend, fullstack (기본: fullstack)
#   -d, --dir       생성 경로 (기본: 현재 디렉토리)
#   -f, --frontend  Frontend 디렉토리 이름 (fullstack 타입에서 사용)
#   -b, --backend   Backend 디렉토리 이름 (fullstack 타입에서 사용)
#   -h, --help      도움말 표시
#######################################

set -e

# 스크립트 디렉토리 (dev-standards 기준)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STANDARDS_PATH="$(dirname "$SCRIPT_DIR")"

# 모듈 로드
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/validators.sh"
source "${SCRIPT_DIR}/lib/prerequisites.sh"
source "${SCRIPT_DIR}/lib/commitlint.sh"
source "${SCRIPT_DIR}/lib/templates-frontend.sh"
source "${SCRIPT_DIR}/lib/templates-backend.sh"
source "${SCRIPT_DIR}/lib/templates-fullstack.sh"

# 기본값
PROJECT_NAME=""
PROJECT_TYPE="fullstack"
TARGET_DIR="$(pwd)"
FRONTEND_DIR=""
BACKEND_DIR=""
PROJECT_WITH_SKILLS=false
PROJECT_WITH_GENERATORS=false

#######################################
# 유틸리티 함수
#######################################

show_help() {
    echo "신규 프로젝트 생성 스크립트"
    echo ""
    echo "사용법:"
    echo "  $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -n, --name <name>        프로젝트 이름 (필수)"
    echo "  -t, --type <type>        프로젝트 타입"
    echo "                           - frontend  : Frontend만 생성"
    echo "                           - backend   : Backend만 생성"
    echo "                           - fullstack : Frontend + Backend (기본값)"
    echo "  -d, --dir <path>         생성 경로 (기본: 현재 디렉토리)"
    echo "  -f, --frontend <name>    Frontend 디렉토리 이름 (fullstack용, 기본: {name}-frontend)"
    echo "  -b, --backend <name>     Backend 디렉토리 이름 (fullstack용, 기본: {name}-backend)"
    echo "  --with-skills            Claude Skills 포함 (manage-skills, verify-implementation)"
    echo "  --with-generators        Code Generators 포함 (API, 컴포넌트, 테스트 생성기)"
    echo "  -h, --help               이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 --name my-project --type fullstack"
    echo "  $0 -n my-app -t frontend"
    echo "  $0 -n api-server -t backend -d /projects"
    echo "  $0 -n edms -t fullstack -f edms-fe -b edms-be"
    echo ""
}

#######################################
# 인자 파싱
#######################################

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -t|--type)
            PROJECT_TYPE="$2"
            shift 2
            ;;
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -f|--frontend)
            FRONTEND_DIR="$2"
            shift 2
            ;;
        -b|--backend)
            BACKEND_DIR="$2"
            shift 2
            ;;
        --with-skills)
            PROJECT_WITH_SKILLS=true
            shift
            ;;
        --with-generators)
            PROJECT_WITH_GENERATORS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

#######################################
# 대화형 입력 (인자가 없는 경우)
#######################################

interactive_input() {
    print_header "신규 프로젝트 생성"

    # 프로젝트 이름
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${YELLOW}프로젝트 이름을 입력하세요 (영문자, 숫자, 하이픈, 언더스코어):${NC}"
        read -p "> " PROJECT_NAME

        if [ -z "$PROJECT_NAME" ]; then
            print_error "프로젝트 이름은 필수입니다."
            exit 1
        fi

        if ! validate_project_name "$PROJECT_NAME"; then
            exit 1
        fi
    fi

    # 프로젝트 타입
    echo ""
    echo -e "${YELLOW}프로젝트 타입을 선택하세요:${NC}"
    echo "  1) frontend  - React + TypeScript + Vite"
    echo "  2) backend   - FastAPI + PostgreSQL"
    echo "  3) fullstack - Frontend + Backend (기본)"
    echo ""
    read -p "선택 [1/2/3, 기본=3]: " type_choice

    case $type_choice in
        1) PROJECT_TYPE="frontend" ;;
        2) PROJECT_TYPE="backend" ;;
        3|"") PROJECT_TYPE="fullstack" ;;
        *)
            print_error "잘못된 선택입니다."
            exit 1
            ;;
    esac

    # Fullstack인 경우 디렉토리 이름 입력
    if [ "$PROJECT_TYPE" == "fullstack" ]; then
        echo ""
        echo -e "${YELLOW}Frontend 디렉토리 이름 (기본: ${PROJECT_NAME}-frontend):${NC}"
        read -p "> " custom_frontend
        if [ -n "$custom_frontend" ]; then
            if ! validate_dir_name "$custom_frontend" "Frontend"; then
                exit 1
            fi
            FRONTEND_DIR="$custom_frontend"
        fi

        echo ""
        echo -e "${YELLOW}Backend 디렉토리 이름 (기본: ${PROJECT_NAME}-backend):${NC}"
        read -p "> " custom_backend
        if [ -n "$custom_backend" ]; then
            if ! validate_dir_name "$custom_backend" "Backend"; then
                exit 1
            fi
            BACKEND_DIR="$custom_backend"
        fi
    fi

    # 생성 경로
    echo ""
    echo -e "${YELLOW}생성 경로를 입력하세요 (기본: 현재 디렉토리):${NC}"
    read -p "> " custom_dir

    if [ -n "$custom_dir" ]; then
        if ! validate_path "$custom_dir"; then
            exit 1
        fi
        TARGET_DIR="$custom_dir"
    fi

    # 추가 기능 선택
    echo ""
    echo -e "${YELLOW}추가 기능을 선택하세요 (Enter로 건너뛰기):${NC}"
    echo "  1) Claude Skills (검증 스킬 자동 관리)"
    echo "  2) Code Generators (코드 생성 도구)"
    echo "  3) 둘 다"
    echo ""
    read -p "선택 [1/2/3, Enter=건너뛰기]: " addon_choice
    case $addon_choice in
        1) PROJECT_WITH_SKILLS=true ;;
        2) PROJECT_WITH_GENERATORS=true ;;
        3) PROJECT_WITH_SKILLS=true; PROJECT_WITH_GENERATORS=true ;;
        *) ;;  # 건너뛰기
    esac
}

#######################################
# 메인 실행
#######################################

main() {
    validate_inputs

    # Fullstack용 기본값 설정
    local actual_frontend_dir="${FRONTEND_DIR:-$PROJECT_NAME-frontend}"
    local actual_backend_dir="${BACKEND_DIR:-$PROJECT_NAME-backend}"

    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  프로젝트 정보${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "  이름: ${GREEN}$PROJECT_NAME${NC}"
    echo -e "  타입: ${GREEN}$PROJECT_TYPE${NC}"
    echo -e "  경로: ${GREEN}$TARGET_DIR/$PROJECT_NAME${NC}"
    if [ "$PROJECT_TYPE" == "fullstack" ]; then
        echo -e "  Frontend: ${GREEN}$actual_frontend_dir${NC}"
        echo -e "  Backend:  ${GREEN}$actual_backend_dir${NC}"
    fi
    echo ""

    read -p "계속 진행하시겠습니까? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi

    case $PROJECT_TYPE in
        frontend)
            create_frontend "$TARGET_DIR/$PROJECT_NAME" "$PROJECT_NAME"
            ;;
        backend)
            create_backend "$TARGET_DIR/$PROJECT_NAME" "$PROJECT_NAME"
            ;;
        fullstack)
            create_fullstack "$TARGET_DIR/$PROJECT_NAME" "$PROJECT_NAME" "$FRONTEND_DIR" "$BACKEND_DIR"
            ;;
    esac

    echo ""
    print_header "생성 완료!"
    echo -e "프로젝트 경로: ${GREEN}$TARGET_DIR/$PROJECT_NAME${NC}"
    echo ""
    echo "다음 단계:"

    case $PROJECT_TYPE in
        frontend)
            echo "  cd $TARGET_DIR/$PROJECT_NAME"
            echo "  pnpm install"
            echo "  pnpm dev"
            ;;
        backend)
            echo "  cd $TARGET_DIR/$PROJECT_NAME"
            echo "  python -m venv .venv && source .venv/bin/activate"
            echo "  uv pip install -e '.[dev]'"
            echo "  cp .env.example .env"
            echo "  uvicorn src.main:app --reload"
            ;;
        fullstack)
            echo "  cd $TARGET_DIR/$PROJECT_NAME"
            echo "  docker-compose up -d"
            echo ""
            echo "또는 개별 실행:"
            echo "  # Frontend"
            echo "  cd $actual_frontend_dir && pnpm install && pnpm dev"
            echo ""
            echo "  # Backend"
            echo "  cd $actual_backend_dir && python -m venv .venv && source .venv/bin/activate"
            echo "  uv pip install -e '.[dev]' && uvicorn src.main:app --reload"
            ;;
    esac
    echo ""
}

main
