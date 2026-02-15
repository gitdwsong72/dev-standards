#!/bin/bash

#######################################
# Commitlint + Husky 설정
#######################################

# Load dependencies
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_LIB}/ui.sh"

setup_commitlint() {
    local project_path="$1"
    local pkg_manager="$2"  # "pnpm" 또는 "uv" (frontend/backend 구분)

    print_step "Commitlint + Husky 설정..."

    cd "$project_path" || return 1

    if [ "$pkg_manager" == "pnpm" ]; then
        # Frontend (Node.js) 프로젝트
        # commitlint 설정 파일 복사
        if [ -f "$STANDARDS_PATH/templates/git/commitlint.config.js" ]; then
            cp "$STANDARDS_PATH/templates/git/commitlint.config.js" commitlint.config.js
        fi

        # package.json에 commitlint, husky devDependencies 추가
        # (실제 install은 사용자가 pnpm install 시 수행)
        local tmp_pkg
        tmp_pkg=$(mktemp)
        node -e "
const pkg = require('./package.json');
pkg.devDependencies = pkg.devDependencies || {};
pkg.devDependencies['@commitlint/cli'] = '^19.0.0';
pkg.devDependencies['@commitlint/config-conventional'] = '^19.0.0';
pkg.devDependencies['husky'] = '^9.0.0';
pkg.scripts = pkg.scripts || {};
pkg.scripts['prepare'] = 'husky';
console.log(JSON.stringify(pkg, null, 2));
" > "$tmp_pkg" 2>/dev/null

        if [ -s "$tmp_pkg" ]; then
            mv "$tmp_pkg" package.json
        else
            rm -f "$tmp_pkg"
            print_warning "package.json 업데이트 실패 (node 필요). 수동으로 추가하세요."
            return
        fi

        # husky 디렉토리 및 commit-msg hook 생성
        mkdir -p .husky
        if [ -f "$STANDARDS_PATH/templates/git/commit-msg-hook.sh" ]; then
            cp "$STANDARDS_PATH/templates/git/commit-msg-hook.sh" .husky/commit-msg
        else
            cat > .husky/commit-msg << 'HOOK'
#!/bin/sh
npx --no -- commitlint --edit "$1"
HOOK
        fi
        chmod +x .husky/commit-msg

        print_success "Commitlint + Husky 설정 완료"
        echo "  → pnpm install 후 자동으로 husky가 초기화됩니다."

    elif [ "$pkg_manager" == "uv" ]; then
        # Backend (Python) 프로젝트 - commitlint은 Node.js 기반이므로 npx 사용
        # commitlint 설정 파일 복사
        if [ -f "$STANDARDS_PATH/templates/git/commitlint.config.js" ]; then
            cp "$STANDARDS_PATH/templates/git/commitlint.config.js" commitlint.config.js
        fi

        # pre-commit 또는 직접 git hook으로 설정
        mkdir -p .githooks
        if [ -f "$STANDARDS_PATH/templates/git/commit-msg-hook.sh" ]; then
            cp "$STANDARDS_PATH/templates/git/commit-msg-hook.sh" .githooks/commit-msg
        else
            cat > .githooks/commit-msg << 'HOOK'
#!/bin/sh
npx --no -- commitlint --edit "$1"
HOOK
        fi
        chmod +x .githooks/commit-msg

        # setup script 생성
        mkdir -p scripts
        cat > scripts/setup-commitlint.sh << 'SETUP'
#!/bin/bash
# Commitlint 설정 스크립트 (Backend 프로젝트용)
#
# Node.js가 설치되어 있어야 합니다.
# 이 스크립트는 최초 1회만 실행하면 됩니다.

set -e

echo "Commitlint 설정 중..."

# git hooks 경로 설정
git config core.hooksPath .githooks

# commitlint 설치 (npx로 실행하므로 전역 설치 불필요)
# 로컬에 캐시하려면 아래 주석 해제:
# npm install --save-dev @commitlint/cli @commitlint/config-conventional

echo "✓ Commitlint 설정 완료"
echo "  → git hooks 경로: .githooks/"
echo "  → 커밋 시 자동으로 메시지가 검증됩니다."
SETUP
        chmod +x scripts/setup-commitlint.sh

        print_success "Commitlint 설정 완료"
        echo "  → scripts/setup-commitlint.sh 실행 후 커밋 메시지 검증이 활성화됩니다."
    fi
}
