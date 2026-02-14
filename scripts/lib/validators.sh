#!/bin/bash

#######################################
# 입력 검증 함수
#######################################

# Load dependencies
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_LIB}/ui.sh"

validate_project_name() {
    local name="$1"

    # 빈 값 체크
    if [ -z "$name" ]; then
        print_error "프로젝트명이 비어있습니다."
        return 1
    fi

    # 영문자, 숫자, 하이픈, 언더스코어만 허용 (command injection 방지)
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "프로젝트명은 영문자, 숫자, 하이픈(-), 언더스코어(_)만 사용 가능합니다."
        return 1
    fi

    # 영문자로 시작해야 함
    if ! [[ "$name" =~ ^[a-zA-Z] ]]; then
        print_error "프로젝트명은 영문자로 시작해야 합니다."
        return 1
    fi

    # 길이 제한 (1~50자)
    if [ ${#name} -gt 50 ]; then
        print_error "프로젝트명은 최대 50자까지 가능합니다."
        return 1
    fi

    # 예약어 차단
    local reserved_names=("test" "." ".." "node_modules" "dist" "build" "src" "tmp" "temp" "root" "admin")
    for reserved in "${reserved_names[@]}"; do
        if [ "$name" = "$reserved" ]; then
            print_error "예약어는 프로젝트명으로 사용할 수 없습니다: $reserved"
            return 1
        fi
    done

    return 0
}

validate_path() {
    local path="$1"

    # 빈 값 체크
    if [ -z "$path" ]; then
        print_error "경로가 비어있습니다."
        return 1
    fi

    # 경로 탐색 공격 방지 (..)
    if [[ "$path" == *".."* ]]; then
        print_error "경로에 '..'를 포함할 수 없습니다."
        return 1
    fi

    # 위험 문자 차단 (command injection 방지)
    if [[ "$path" =~ [';|&$`\\'] ]]; then
        print_error "경로에 특수문자를 사용할 수 없습니다."
        return 1
    fi

    return 0
}

validate_dir_name() {
    local name="$1"
    local label="$2"

    if [ -z "$name" ]; then
        return 0  # 빈 값은 기본값 사용
    fi

    # 영문자, 숫자, 하이픈, 언더스코어만 허용
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "${label} 디렉토리명은 영문자, 숫자, 하이픈(-), 언더스코어(_)만 사용 가능합니다."
        return 1
    fi

    if [ ${#name} -gt 50 ]; then
        print_error "${label} 디렉토리명은 최대 50자까지 가능합니다."
        return 1
    fi

    return 0
}

validate_inputs() {
    # 프로젝트 이름 입력 (대화형)
    if [ -z "$PROJECT_NAME" ]; then
        interactive_input
    fi

    # 프로젝트 이름 보안 검증
    if ! validate_project_name "$PROJECT_NAME"; then
        exit 1
    fi

    # 프로젝트 타입 검증
    case $PROJECT_TYPE in
        frontend|backend|fullstack) ;;
        *)
            print_error "잘못된 프로젝트 타입: $PROJECT_TYPE"
            print_error "사용 가능: frontend, backend, fullstack"
            exit 1
            ;;
    esac

    # 대상 디렉토리 경로 보안 검증
    if ! validate_path "$TARGET_DIR"; then
        exit 1
    fi

    # 대상 디렉토리 존재 여부 검증
    if [ ! -d "$TARGET_DIR" ]; then
        print_error "대상 디렉토리가 존재하지 않습니다: $TARGET_DIR"
        exit 1
    fi

    # Fullstack 디렉토리 이름 검증
    if [ -n "$FRONTEND_DIR" ]; then
        if ! validate_dir_name "$FRONTEND_DIR" "Frontend"; then
            exit 1
        fi
    fi
    if [ -n "$BACKEND_DIR" ]; then
        if ! validate_dir_name "$BACKEND_DIR" "Backend"; then
            exit 1
        fi
    fi

    # 필수 도구 체크
    check_prerequisites
}
