#!/bin/bash

#######################################
# Frontend 프로젝트 생성 템플릿
#######################################

# Load dependencies
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_LIB}/ui.sh"
source "${SCRIPT_DIR_LIB}/commitlint.sh"

create_frontend() {
    local project_path="$1"
    local project_name="$2"

    print_header "Frontend 프로젝트 생성: $project_name"

    # 디렉토리 생성
    print_step "디렉토리 생성..."
    mkdir -p "$project_path"
    cd "$project_path" || return 1

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

    # Claude Skills 복사
    if [ "$PROJECT_WITH_SKILLS" = true ]; then
        print_step "Claude Skills 복사..."
        mkdir -p .claude/skills
        cp -r "$STANDARDS_PATH/templates/claude-skills/manage-skills" .claude/skills/
        cp -r "$STANDARDS_PATH/templates/claude-skills/verify-implementation" .claude/skills/
        cp -r "$STANDARDS_PATH/templates/claude-skills/dev-toolkit" .claude/skills/
    fi

    # Code Generators 복사
    if [ "$PROJECT_WITH_GENERATORS" = true ]; then
        print_step "Code Generators 복사..."
        mkdir -p scripts/generators
        cp "$STANDARDS_PATH/scripts/generators/"*.py scripts/generators/
        cp "$STANDARDS_PATH/scripts/generators/__init__.py" scripts/generators/ 2>/dev/null || touch scripts/generators/__init__.py
        mkdir -p templates/code-generators
        cp "$STANDARDS_PATH/templates/code-generators/"* templates/code-generators/
    fi

    print_success "Frontend 프로젝트 생성 완료: $project_path"
}
