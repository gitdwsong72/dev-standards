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

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 스크립트 디렉토리 (dev-standards 기준)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STANDARDS_PATH="$(dirname "$SCRIPT_DIR")"

# 기본값
PROJECT_NAME=""
PROJECT_TYPE="fullstack"
TARGET_DIR="$(pwd)"
FRONTEND_DIR=""
BACKEND_DIR=""

#######################################
# 유틸리티 함수
#######################################

print_header() {
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

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
}

#######################################
# 입력 검증 (보안)
#######################################

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

#######################################
# 검증
#######################################

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

#######################################
# Commitlint + Husky 설정
#######################################

setup_commitlint() {
    local project_path="$1"
    local pkg_manager="$2"  # "pnpm" 또는 "uv" (frontend/backend 구분)

    print_step "Commitlint + Husky 설정..."

    cd "$project_path"

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

#######################################
# Frontend 프로젝트 생성
#######################################

create_frontend() {
    local project_path="$1"
    local project_name="$2"

    print_header "Frontend 프로젝트 생성: $project_name"

    # 디렉토리 생성
    print_step "디렉토리 생성..."
    mkdir -p "$project_path"
    cd "$project_path"

    # Vite 프로젝트 초기화 (package.json만 생성)
    print_step "Vite + React + TypeScript 초기화..."

    # package.json 직접 생성 (vite create의 인터랙티브 프롬프트 회피)
    cat > package.json << 'PKGJSON'
{
  "name": "frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint src --ext ts,tsx",
    "lint:fix": "eslint src --ext ts,tsx --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,css}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,css}\"",
    "typecheck": "tsc --noEmit",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "typescript": "^5.5.3",
    "vite": "^5.4.2",
    "@playwright/test": "^1.45.0",
    "eslint": "^9.0.0",
    "@eslint/js": "^9.0.0",
    "globals": "^15.0.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "eslint-plugin-react-refresh": "^0.4.7",
    "typescript-eslint": "^8.0.0",
    "prettier": "^3.3.0"
  }
}
PKGJSON

    # package.json의 name 필드를 프로젝트 이름으로 업데이트
    sed -i.bak "s/\"name\": \"frontend\"/\"name\": \"$project_name\"/" package.json && rm -f package.json.bak

    # 기본 소스 파일 생성
    mkdir -p src

    # index.html
    cat > index.html << 'INDEXHTML'
<!doctype html>
<html lang="ko">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Vite + React + TS</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
INDEXHTML

    # src/main.tsx
    cat > src/main.tsx << 'MAINTSX'
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
MAINTSX

    # src/App.tsx
    cat > src/App.tsx << 'APPTSX'
function App() {
  return (
    <div>
      <h1>Hello, World!</h1>
    </div>
  );
}

export default App;
APPTSX

    # src/vite-env.d.ts
    cat > src/vite-env.d.ts << 'VITEDTS'
/// <reference types="vite/client" />
VITEDTS

    # 디렉토리 구조 생성
    print_step "디렉토리 구조 생성..."
    mkdir -p src/{domains,shared/components/{DataGrid,Charts}}
    mkdir -p .claude/{agents,commands,scripts}
    mkdir -p docs/prd/{common,screens}
    mkdir -p tests/e2e/{pages,fixtures}
    mkdir -p nginx/{conf.d,lua,ssl}

    # 설정 파일 생성
    print_step "설정 파일 생성..."

    # eslint.config.js (독립 실행 가능)
    cat > eslint.config.js << 'EOF'
import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist', 'node_modules', '*.config.js'] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },
);
EOF

    # prettier.config.js (독립 실행 가능)
    cat > prettier.config.js << 'EOF'
export default {
  semi: true,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'es5',
  printWidth: 100,
};
EOF

    # tsconfig.json (독립 실행 가능)
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["src/shared/*"],
      "@domains/*": ["src/domains/*"]
    }
  },
  "include": ["src/**/*", "vite.config.ts"],
  "exclude": ["node_modules", "dist"]
}
EOF

    # vite.config.ts
    cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@shared': path.resolve(__dirname, './src/shared'),
      '@domains': path.resolve(__dirname, './src/domains'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
});
EOF

    # playwright.config.ts
    cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html', { outputFolder: 'playwright-report' }], ['list']],
  use: {
    baseURL: 'http://localhost:5173',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  ],
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
  },
});
EOF

    # .env.example
    cat > .env.example << EOF
VITE_API_URL=http://localhost:8000
VITE_ENV=development
EOF

    # .node-version, .nvmrc
    echo "20" > .node-version
    echo "20" > .nvmrc

    # .gitignore
    cat > .gitignore << 'EOF'
node_modules/
dist/
.vite/
coverage/
playwright-report/
test-results/
.env
.env.local
.env.*.local
.DS_Store
*.log
EOF

    # Dockerfile (운영용)
    print_step "Dockerfile 생성..."
    cat > Dockerfile << 'EOF'
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

    # Dockerfile.dev (개발용)
    cat > Dockerfile.dev << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN corepack enable && pnpm install
COPY . .
EXPOSE 5173
CMD ["pnpm", "dev", "--host"]
EOF

    # nginx 설정
    print_step "Nginx 설정 생성..."
    cat > nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA 라우팅
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 프록시
    location /api {
        proxy_pass http://backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # gzip 압축
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF

    # docker-compose.yml (Frontend 단독 실행용)
    print_step "docker-compose.yml 생성..."
    cat > docker-compose.yml << 'EOF'
services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "5173:5173"
    volumes:
      - ./src:/app/src
      - ./package.json:/app/package.json
      - /app/node_modules
    environment:
      - VITE_API_URL=http://localhost:8000
EOF

    # PRD 템플릿 복사
    print_step "PRD 템플릿 복사..."
    if [ -d "$STANDARDS_PATH/templates/prd" ]; then
        cp "$STANDARDS_PATH/templates/prd/common.md" docs/prd/common/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/prd/screen.md" docs/prd/screens/_template.md 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/prd/index.md" docs/prd/ 2>/dev/null || true
    fi

    # Claude 설정 복사
    print_step "Claude Code 설정 복사..."
    if [ -d "$STANDARDS_PATH/templates/claude-agents" ]; then
        cp "$STANDARDS_PATH/templates/claude-agents/react-specialist.md" .claude/agents/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/e2e-test-specialist.md" .claude/agents/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/code-quality-reviewer.md" .claude/agents/ 2>/dev/null || true
    fi

    # Hooks 스크립트 복사 (settings.json은 Claude Code 버전에 따라 수동 설정 필요)
    if [ -d "$STANDARDS_PATH/templates/hooks/frontend" ]; then
        cp "$STANDARDS_PATH/templates/hooks/frontend/check-env.sh" .claude/scripts/ 2>/dev/null || true
        chmod +x .claude/scripts/check-env.sh 2>/dev/null || true
    fi

    # 개발 표준 문서 복사
    print_step "개발 표준 문서 복사..."
    mkdir -p docs/standards
    if [ -d "$STANDARDS_PATH/docs" ]; then
        cp "$STANDARDS_PATH/docs/git-workflow.md" docs/standards/ 2>/dev/null || true
        cp "$STANDARDS_PATH/docs/commit-convention.md" docs/standards/ 2>/dev/null || true
    fi
    if [ -d "$STANDARDS_PATH/templates/workflows" ]; then
        cp "$STANDARDS_PATH/templates/workflows/development-workflow.md" docs/standards/ 2>/dev/null || true
    fi

    # CLAUDE.md 생성
    print_step "CLAUDE.md 생성..."
    cat > CLAUDE.md << 'CLAUDEMD'
# CLAUDE.md - Frontend Project

## 필수 참조 문서
**중요**: 코드 작성 전 반드시 아래 문서를 읽고 규칙을 준수하세요.
- `docs/standards/git-workflow.md` - Git 브랜치 전략, 커밋 규칙
- `docs/standards/commit-convention.md` - 커밋 메시지 컨벤션
- `docs/standards/development-workflow.md` - 개발 워크플로우

## 핵심 규칙 요약

### Git 규칙
- 브랜치: `master` → `SKTL-XXXX` (JIRA 티켓) → `develop` → `master`
- 로컬에서 master 직접 push/merge 금지
- 커밋 메시지: `type(scope): description` 형식

### 코드 규칙
- 새 기능은 `src/domains/{도메인}/` 하위에 작성
- 공통 컴포넌트는 `src/shared/components/`에 작성
- 상태 관리는 Zustand 사용
- 타입은 각 도메인의 `types/` 폴더에 정의

### 테스트 규칙
- E2E 테스트: `tests/e2e/` 디렉토리
- Page Object Model 패턴 사용
- 테스트 파일명: `*.spec.ts`

CLAUDEMD

    cat >> CLAUDE.md << EOF

## 프로젝트 정보

**프로젝트명**: $project_name

## 기술 스택
- **Framework**: React 18
- **Language**: TypeScript 5
- **Build Tool**: Vite
- **State Management**: Zustand
- **Grid**: AG-Grid
- **Charts**: Recharts

## 개발 명령어

\`\`\`bash
pnpm dev          # 개발 서버
pnpm build        # 빌드
pnpm lint         # 린트 검사
pnpm format       # 포맷팅
pnpm typecheck    # 타입 체크
pnpm test:e2e     # E2E 테스트
\`\`\`

## 프로젝트 구조

\`\`\`
src/
├── domains/          # 업무 도메인별 폴더
│   └── {domain}/
│       ├── components/
│       ├── hooks/
│       ├── stores/
│       ├── pages/
│       ├── api/
│       └── types/
└── shared/           # 공통 모듈
    └── components/
\`\`\`

## Claude Code Agents

- \`@react-specialist\` - React, AG-Grid, Zustand 전문
- \`@e2e-test-specialist\` - Playwright E2E 테스트
- \`@code-quality-reviewer\` - 코드 품질 리뷰

## 문서
- [Git 워크플로우](docs/standards/git-workflow.md)
- [커밋 컨벤션](docs/standards/commit-convention.md)
- [개발 워크플로우](docs/standards/development-workflow.md)
EOF

    # README.md 생성
    cat > README.md << EOF
# $project_name

React + TypeScript 기반 SPA 프로젝트입니다.

## 시작하기

\`\`\`bash
# 의존성 설치
pnpm install

# 개발 서버 실행
pnpm dev
\`\`\`

## 기술 스택

- React 18
- TypeScript 5
- Vite
- Zustand
- AG-Grid
- Recharts

## 문서

- [CLAUDE.md](CLAUDE.md) - Claude Code 가이드
- [Git 워크플로우](docs/standards/git-workflow.md)
- [커밋 컨벤션](docs/standards/commit-convention.md)
- [개발 워크플로우](docs/standards/development-workflow.md)
EOF

    # Commitlint + Husky 설정
    setup_commitlint "$project_path" "pnpm"

    print_success "Frontend 프로젝트 생성 완료: $project_path"
}

#######################################
# Backend 프로젝트 생성
#######################################

create_backend() {
    local project_path="$1"
    local project_name="$2"

    print_header "Backend 프로젝트 생성: $project_name"

    # 디렉토리 생성
    print_step "디렉토리 생성..."
    mkdir -p "$project_path"
    cd "$project_path"

    # 디렉토리 구조 생성
    print_step "디렉토리 구조 생성..."
    mkdir -p src/{domains,shared/{database,patterns,utils}}
    mkdir -p .claude/{agents,commands,scripts}
    mkdir -p docs/prd/{common,endpoints}
    mkdir -p tests/{unit,integration}
    mkdir -p scripts

    # __init__.py 생성
    touch src/__init__.py
    touch src/domains/__init__.py
    touch src/shared/__init__.py
    touch src/shared/database/__init__.py
    touch src/shared/patterns/__init__.py
    touch src/shared/utils/__init__.py
    touch tests/__init__.py
    touch tests/unit/__init__.py
    touch tests/integration/__init__.py

    # pyproject.toml
    print_step "pyproject.toml 생성..."
    cat > pyproject.toml << EOF
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "$project_name"
version = "0.1.0"
description = "$project_name - FastAPI Backend"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.111.0",
    "uvicorn[standard]>=0.29.0",
    "asyncpg>=0.29.0",
    "pydantic>=2.7.0",
    "pydantic-settings>=2.2.0",
    "python-dotenv>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.27.0",
    "ruff>=0.4.0",
    "mypy>=1.10.0",
]

[tool.hatch.build.targets.wheel]
packages = ["src"]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "ARG", "SIM", "TCH", "PTH", "ERA", "PL", "RUF", "ASYNC", "S"]
ignore = ["E501", "PLR0913", "PLR2004"]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["S101", "ARG"]

[tool.ruff.lint.isort]
known-first-party = ["src"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
EOF

    # src/main.py
    print_step "main.py 생성..."
    cat > src/main.py << 'EOF'
"""FastAPI 애플리케이션 진입점."""

from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.shared.database import db_pool


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """애플리케이션 생명주기 관리."""
    await db_pool.initialize()
    yield
    await db_pool.close()


app = FastAPI(
    title="API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 도메인 라우터 등록
# from src.domains.example import router as example_router
# app.include_router(example_router)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """헬스 체크 엔드포인트."""
    return {"status": "healthy"}
EOF

    # src/shared/database/connection.py
    print_step "Database 모듈 생성..."
    cat > src/shared/database/connection.py << 'EOF'
"""Database connection management."""

from contextlib import asynccontextmanager
from typing import AsyncIterator

import asyncpg
from pydantic_settings import BaseSettings


class DatabaseSettings(BaseSettings):
    """Database connection settings."""

    primary_db_url: str = "postgresql://user:password@localhost:5432/appdb"
    replica_db_url: str | None = None

    class Config:
        env_prefix = "DB_"


class DatabasePool:
    """Manages database connection pools."""

    def __init__(self) -> None:
        self._primary_pool: asyncpg.Pool | None = None
        self._replica_pool: asyncpg.Pool | None = None
        self._settings = DatabaseSettings()

    async def initialize(self) -> None:
        """Initialize database connection pools."""
        self._primary_pool = await asyncpg.create_pool(
            self._settings.primary_db_url,
            min_size=5,
            max_size=20,
            command_timeout=60,
        )
        if self._settings.replica_db_url:
            self._replica_pool = await asyncpg.create_pool(
                self._settings.replica_db_url,
                min_size=5,
                max_size=20,
                command_timeout=60,
            )

    async def close(self) -> None:
        """Close all database connection pools."""
        if self._primary_pool:
            await self._primary_pool.close()
        if self._replica_pool:
            await self._replica_pool.close()

    @asynccontextmanager
    async def acquire_primary(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection from the primary pool."""
        if not self._primary_pool:
            raise RuntimeError("Database pool not initialized")
        async with self._primary_pool.acquire() as connection:
            yield connection

    @asynccontextmanager
    async def acquire_replica(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection from the replica pool."""
        pool = self._replica_pool or self._primary_pool
        if not pool:
            raise RuntimeError("Database pool not initialized")
        async with pool.acquire() as connection:
            yield connection


db_pool = DatabasePool()


async def get_db_connection() -> AsyncIterator[asyncpg.Connection]:
    """FastAPI dependency for database connection."""
    async with db_pool.acquire_primary() as connection:
        yield connection


async def get_readonly_connection() -> AsyncIterator[asyncpg.Connection]:
    """FastAPI dependency for read-only database connection."""
    async with db_pool.acquire_replica() as connection:
        yield connection
EOF

    # src/shared/database/transaction.py
    cat > src/shared/database/transaction.py << 'EOF'
"""Transaction management utilities."""

from contextlib import asynccontextmanager
from typing import AsyncIterator

import asyncpg


@asynccontextmanager
async def transaction(
    connection: asyncpg.Connection,
    isolation: str = "read_committed",
) -> AsyncIterator[asyncpg.Connection]:
    """Context manager for database transactions."""
    async with connection.transaction(isolation=isolation):
        yield connection


@asynccontextmanager
async def savepoint(
    connection: asyncpg.Connection,
    name: str | None = None,
) -> AsyncIterator[asyncpg.Connection]:
    """Context manager for savepoints within a transaction."""
    if name:
        await connection.execute(f"SAVEPOINT {name}")
        try:
            yield connection
            await connection.execute(f"RELEASE SAVEPOINT {name}")
        except Exception:
            await connection.execute(f"ROLLBACK TO SAVEPOINT {name}")
            raise
    else:
        async with connection.transaction():
            yield connection
EOF

    # src/shared/database/__init__.py
    cat > src/shared/database/__init__.py << 'EOF'
"""Database utilities package."""

from .connection import (
    DatabasePool,
    db_pool,
    get_db_connection,
    get_readonly_connection,
)
from .transaction import savepoint, transaction

__all__ = [
    "DatabasePool",
    "db_pool",
    "get_db_connection",
    "get_readonly_connection",
    "savepoint",
    "transaction",
]
EOF

    # src/shared/utils/sql_loader.py
    cat > src/shared/utils/sql_loader.py << 'EOF'
"""SQL file loader utility."""

from functools import lru_cache
from pathlib import Path


class SQLLoader:
    """Loads and caches SQL files from a domain's sql directory."""

    def __init__(self, domain: str, base_path: Path | None = None) -> None:
        self.domain = domain
        if base_path is None:
            base_path = Path(__file__).parent.parent.parent / "domains"
        self.sql_path = base_path / domain / "sql"

    @lru_cache(maxsize=100)
    def load(self, filename: str) -> str:
        """Load a SQL file and cache the result."""
        file_path = self.sql_path / filename
        if not file_path.exists():
            raise FileNotFoundError(f"SQL file not found: {file_path}")
        return file_path.read_text(encoding="utf-8").strip()


def create_sql_loader(domain: str) -> SQLLoader:
    """Create a SQL loader for a specific domain."""
    return SQLLoader(domain)
EOF

    # src/shared/utils/__init__.py
    cat > src/shared/utils/__init__.py << 'EOF'
"""Shared utilities package."""

from .sql_loader import SQLLoader, create_sql_loader

__all__ = ["SQLLoader", "create_sql_loader"]
EOF

    # tests/conftest.py
    print_step "테스트 설정 생성..."
    cat > tests/conftest.py << 'EOF'
"""pytest fixtures."""

from collections.abc import AsyncGenerator
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from src.main import app


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    """Test HTTP client."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac


@pytest.fixture
def mock_repository() -> MagicMock:
    """Mock repository for unit tests."""
    return MagicMock()


@pytest.fixture
def sample_data() -> dict[str, Any]:
    """Sample test data."""
    return {
        "id": 1,
        "name": "Test Item",
        "created_at": "2024-01-01T00:00:00Z",
    }
EOF

    # .env.example
    cat > .env.example << EOF
DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@localhost:5432/$project_name
# DB_REPLICA_DB_URL=postgresql://devuser:devpassword@localhost:5432/${project_name}_replica
ENV=development
DEBUG=true
EOF

    # .python-version
    echo "3.11" > .python-version

    # .gitignore
    cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.venv/
venv/
.pytest_cache/
.coverage
htmlcov/
.mypy_cache/
.env
.env.local
.DS_Store
*.log
EOF

    # Dockerfile
    print_step "Dockerfile 생성..."
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY pyproject.toml ./
RUN pip install --no-cache-dir uv && \
    uv pip install --system -e .

# 소스 코드 복사
COPY src/ ./src/

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

    # docker-compose.yml (Backend 단독 실행용 - DB 포함)
    print_step "docker-compose.yml 생성..."
    cat > docker-compose.yml << 'EOF'
services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@db:5432/appdb
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./src:/app/src
    command: uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=devuser
      - POSTGRES_PASSWORD=devpassword
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U devuser -d appdb"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

    # PRD 템플릿 복사
    print_step "PRD 템플릿 복사..."
    if [ -d "$STANDARDS_PATH/templates/prd" ]; then
        cp "$STANDARDS_PATH/templates/prd/common.md" docs/prd/common/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/prd/endpoint.md" docs/prd/endpoints/_template.md 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/prd/index.md" docs/prd/ 2>/dev/null || true
    fi

    # Claude 설정 복사
    print_step "Claude Code 설정 복사..."
    if [ -d "$STANDARDS_PATH/templates/claude-agents" ]; then
        cp "$STANDARDS_PATH/templates/claude-agents/fastapi-specialist.md" .claude/agents/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/sql-query-specialist.md" .claude/agents/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/api-test-specialist.md" .claude/agents/ 2>/dev/null || true
    fi

    # Hooks 스크립트 복사 (settings.json은 Claude Code 버전에 따라 수동 설정 필요)
    if [ -d "$STANDARDS_PATH/templates/hooks/backend" ]; then
        cp "$STANDARDS_PATH/templates/hooks/backend/check-env.sh" .claude/scripts/ 2>/dev/null || true
        chmod +x .claude/scripts/check-env.sh 2>/dev/null || true
    fi

    # API 응답 포맷 템플릿 복사
    print_step "API 응답 포맷 템플릿 복사..."
    if [ -d "$STANDARDS_PATH/templates/backend" ]; then
        mkdir -p src/shared/response
        cp "$STANDARDS_PATH/templates/backend/response_schemas.py" src/shared/response/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/backend/response_utils.py" src/shared/response/ 2>/dev/null || true
        touch src/shared/response/__init__.py
        cat > src/shared/response/__init__.py << 'EOF'
"""API 응답 포맷 유틸리티."""

from .response_schemas import (
    ErrorDetail,
    ErrorInfo,
    ErrorResponse,
    PaginatedData,
    PaginationInfo,
    ResponseMeta,
    SuccessResponse,
)
from .response_utils import error_response, success_response

__all__ = [
    "ErrorDetail",
    "ErrorInfo",
    "ErrorResponse",
    "PaginatedData",
    "PaginationInfo",
    "ResponseMeta",
    "SuccessResponse",
    "error_response",
    "success_response",
]
EOF
    fi

    # 개발 표준 문서 복사
    print_step "개발 표준 문서 복사..."
    mkdir -p docs/standards
    if [ -d "$STANDARDS_PATH/docs" ]; then
        cp "$STANDARDS_PATH/docs/git-workflow.md" docs/standards/ 2>/dev/null || true
        cp "$STANDARDS_PATH/docs/commit-convention.md" docs/standards/ 2>/dev/null || true
    fi
    if [ -d "$STANDARDS_PATH/templates/workflows" ]; then
        cp "$STANDARDS_PATH/templates/workflows/development-workflow.md" docs/standards/ 2>/dev/null || true
    fi

    # CLAUDE.md 생성
    print_step "CLAUDE.md 생성..."
    cat > CLAUDE.md << 'CLAUDEMD'
# CLAUDE.md - Backend Project

## 필수 참조 문서
**중요**: 코드 작성 전 반드시 아래 문서를 읽고 규칙을 준수하세요.
- `docs/standards/git-workflow.md` - Git 브랜치 전략, 커밋 규칙
- `docs/standards/commit-convention.md` - 커밋 메시지 컨벤션
- `docs/standards/development-workflow.md` - 개발 워크플로우

## 핵심 규칙 요약

### Git 규칙
- 브랜치: `master` → `SKTL-XXXX` (JIRA 티켓) → `develop` → `master`
- 로컬에서 master 직접 push/merge 금지
- 커밋 메시지: `type(scope): description` 형식

### 코드 규칙
- 새 도메인은 `src/domains/{도메인}/` 하위에 작성
- 레이어 패턴 준수: Router → Service → Repository
- SQL은 `sql/` 폴더에 파일로 분리
- ORM 사용 금지, 순수 SQL + asyncpg 사용

### 트랜잭션 규칙
- Service 레벨에서 트랜잭션 관리
- Repository는 connection만 받아서 사용 (트랜잭션 시작 금지)
- 복수 DB 작업 시 Saga 패턴 사용

### 테스트 규칙
- 단위 테스트: `tests/unit/`
- 통합 테스트: `tests/integration/`
- AAA 패턴 (Arrange-Act-Assert) 사용

CLAUDEMD

    cat >> CLAUDE.md << EOF

## 프로젝트 정보

**프로젝트명**: $project_name

## 기술 스택
- **Framework**: FastAPI
- **Database**: PostgreSQL
- **Driver**: asyncpg
- **Validation**: Pydantic v2
- **Python**: 3.11+

## 개발 명령어

\`\`\`bash
# 개발 서버
uvicorn src.main:app --reload --port 8000

# 린트
ruff check src tests

# 포맷팅
ruff format src tests

# 타입 체크
mypy src

# 테스트
pytest
pytest --cov=src
\`\`\`

## 프로젝트 구조

\`\`\`
src/
├── domains/              # 업무 도메인
│   └── {domain}/
│       ├── router.py     # API 엔드포인트
│       ├── service.py    # 비즈니스 로직
│       ├── repository.py # 데이터 접근
│       ├── schemas.py    # Pydantic 스키마
│       └── sql/          # SQL 파일
├── shared/
│   ├── database/         # DB 연결, 트랜잭션
│   └── utils/            # 유틸리티
└── main.py
\`\`\`

## Claude Code Agents

- \`@fastapi-specialist\` - FastAPI API 설계
- \`@sql-query-specialist\` - PostgreSQL 쿼리
- \`@api-test-specialist\` - pytest API 테스트

## 문서
- [Git 워크플로우](docs/standards/git-workflow.md)
- [커밋 컨벤션](docs/standards/commit-convention.md)
- [개발 워크플로우](docs/standards/development-workflow.md)
EOF

    # README.md 생성
    cat > README.md << EOF
# $project_name

FastAPI + PostgreSQL 기반 백엔드 프로젝트입니다.

## 시작하기

\`\`\`bash
# 가상환경 생성
python -m venv .venv
source .venv/bin/activate

# 의존성 설치
uv pip install -e ".[dev]"

# 환경 변수 설정
cp .env.example .env

# 개발 서버 실행
uvicorn src.main:app --reload --port 8000
\`\`\`

## 기술 스택

- FastAPI
- PostgreSQL + asyncpg
- Pydantic v2
- Python 3.11+

## 문서

- [CLAUDE.md](CLAUDE.md) - Claude Code 가이드
- [Git 워크플로우](docs/standards/git-workflow.md)
- [커밋 컨벤션](docs/standards/commit-convention.md)
- [개발 워크플로우](docs/standards/development-workflow.md)
EOF

    # Commitlint 설정
    setup_commitlint "$project_path" "uv"

    print_success "Backend 프로젝트 생성 완료: $project_path"
}

#######################################
# Fullstack 프로젝트 생성
#######################################

create_fullstack() {
    local base_path="$1"
    local project_name="$2"
    local frontend_dir="$3"
    local backend_dir="$4"

    # 기본값 설정
    if [ -z "$frontend_dir" ]; then
        frontend_dir="$project_name-frontend"
    fi
    if [ -z "$backend_dir" ]; then
        backend_dir="$project_name-backend"
    fi

    print_header "Fullstack 프로젝트 생성: $project_name"
    echo -e "  Frontend: ${GREEN}$frontend_dir${NC}"
    echo -e "  Backend:  ${GREEN}$backend_dir${NC}"

    # 루트 디렉토리 생성
    mkdir -p "$base_path"

    # Frontend 생성
    create_frontend "$base_path/$frontend_dir" "$frontend_dir"

    # Backend 생성
    create_backend "$base_path/$backend_dir" "$backend_dir"

    # 루트 docker-compose.yml 생성
    print_step "루트 docker-compose.yml 생성..."
    cat > "$base_path/docker-compose.yml" << EOF
services:
  frontend:
    build:
      context: ./$frontend_dir
      dockerfile: Dockerfile.dev
    ports:
      - "5173:5173"
    depends_on:
      - backend
    volumes:
      - ./$frontend_dir/src:/app/src
      - ./$frontend_dir/package.json:/app/package.json
      - /app/node_modules

  backend:
    build:
      context: ./$backend_dir
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@db:5432/appdb
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./$backend_dir/src:/app/src
    command: uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=devuser
      - POSTGRES_PASSWORD=devpassword
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U devuser -d appdb"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

    # Fullstack Team 설정: 모든 Agent + Team 템플릿을 양쪽에 복사
    print_step "Fullstack Team 템플릿 설정..."
    if [ -d "$STANDARDS_PATH/templates/claude-agents" ]; then
        # Frontend에 Backend Agent 추가
        cp "$STANDARDS_PATH/templates/claude-agents/fastapi-specialist.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/sql-query-specialist.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/api-test-specialist.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true

        # Backend에 Frontend Agent 추가
        cp "$STANDARDS_PATH/templates/claude-agents/react-specialist.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/e2e-test-specialist.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/code-quality-reviewer.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
    fi

    # Team Lead 템플릿을 양쪽에 복사
    if [ -d "$STANDARDS_PATH/templates/claude-teams" ]; then
        cp "$STANDARDS_PATH/templates/claude-teams/fullstack-team.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-teams/fullstack-team.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
    fi

    # Fullstack Team 가이드 복사
    if [ -d "$STANDARDS_PATH/templates/workflows" ]; then
        cp "$STANDARDS_PATH/templates/workflows/fullstack-team-guide.md" "$base_path/$frontend_dir/docs/standards/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/workflows/fullstack-team-guide.md" "$base_path/$backend_dir/docs/standards/" 2>/dev/null || true
    fi

    print_success "Team 템플릿 설정 완료 (양쪽 프로젝트에 전체 Agent + Team Lead 복사)"

    # Frontend CLAUDE.md에 Team 정보 추가
    cat >> "$base_path/$frontend_dir/CLAUDE.md" << 'EOF'

## Claude Code Team

- `@fullstack-team` - Fullstack 기능 병렬 개발 (Backend + Frontend + Test + Review)

### Team 사용 예시
```bash
@fullstack-team 매출 목록 페이지 구현
```

자세한 사용법은 [Fullstack Team Guide](docs/standards/fullstack-team-guide.md) 참조
EOF

    # Backend CLAUDE.md에 Team 정보 추가
    cat >> "$base_path/$backend_dir/CLAUDE.md" << 'EOF'

## Claude Code Team

- `@fullstack-team` - Fullstack 기능 병렬 개발 (Backend + Frontend + Test + Review)

### Team 사용 예시
```bash
@fullstack-team 매출 목록 페이지 구현
```

자세한 사용법은 [Fullstack Team Guide](docs/standards/fullstack-team-guide.md) 참조
EOF

    # 루트 README.md 생성
    cat > "$base_path/README.md" << EOF
# $project_name

Fullstack 프로젝트 (Frontend + Backend)

## 구조

\`\`\`
$project_name/
├── $frontend_dir/     # React + TypeScript
├── $backend_dir/      # FastAPI + PostgreSQL
└── docker-compose.yml # 통합 실행
\`\`\`

## 시작하기

### Docker로 전체 실행
\`\`\`bash
docker-compose up -d
\`\`\`

### 개별 실행

**Frontend:**
\`\`\`bash
cd $frontend_dir
pnpm install
pnpm dev
\`\`\`

**Backend:**
\`\`\`bash
cd $backend_dir
python -m venv .venv
source .venv/bin/activate
uv pip install -e ".[dev]"
uvicorn src.main:app --reload --port 8000
\`\`\`

## Claude Code Team

Fullstack 기능을 병렬로 개발하려면:
\`\`\`bash
# Frontend 또는 Backend 디렉토리에서
@fullstack-team 매출 목록 페이지 구현
\`\`\`

## 접속 URL

- Frontend: http://localhost:5173 (개발) / http://localhost:80 (Docker)
- Backend API: http://localhost:8000
- API 문서: http://localhost:8000/docs
EOF

    print_success "Fullstack 프로젝트 생성 완료: $base_path"
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
