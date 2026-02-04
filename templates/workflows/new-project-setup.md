# 신규 프로젝트 생성 가이드

이 문서는 dev-standards 표준을 적용한 신규 프로젝트 생성 방법을 설명합니다.

---

## 0. 사전 요구사항

프로젝트 생성 전에 다음 도구들이 설치되어 있어야 합니다.

### Frontend
- **Node.js** (v20 이상): https://nodejs.org/
- **pnpm** (권장) 또는 npm
  ```bash
  npm install -g pnpm
  ```

### Backend
- **Python** (3.11 이상): https://www.python.org/
- **uv** (빠른 Python 패키지 관리자)
  ```bash
  # macOS / Linux
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # Windows (PowerShell)
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

  # 또는 pip로 설치
  pip install uv
  ```

  > 설치 후 터미널 재시작 또는 `source ~/.bashrc` (또는 `~/.zshrc`) 실행 필요

---

## 1. 자동화 스크립트 (권장)

가장 빠르게 프로젝트를 생성하려면 통합 스크립트를 사용하세요.

### 스크립트 위치
```
dev-standards/scripts/create-project.sh
```

### 사용법

```bash
# 대화형 모드 (프롬프트로 입력 받음)
./scripts/create-project.sh

# 명령줄 인자로 지정
./scripts/create-project.sh --name my-project --type fullstack
./scripts/create-project.sh -n my-app -t frontend
./scripts/create-project.sh -n api-server -t backend -d /projects

# 도움말
./scripts/create-project.sh --help
```

### 옵션
| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `-n`, `--name` | 프로젝트 이름 | (필수) |
| `-t`, `--type` | 프로젝트 타입 (frontend, backend, fullstack) | fullstack |
| `-d`, `--dir` | 생성 경로 | 현재 디렉토리 |

### 스크립트가 생성하는 것
- **frontend**: Vite + React + TypeScript 프로젝트, 표준 설정 파일, Claude agents, OpenResty 설정
- **backend**: FastAPI + asyncpg 프로젝트, 표준 설정, Claude agents, 공통 모듈
- **fullstack**: frontend + backend + docker-compose.yml

### 생성 후 다음 단계

**Frontend:**
```bash
cd my-project
pnpm install
pnpm dev
```

**Backend:**
```bash
cd my-project
python -m venv .venv && source .venv/bin/activate
uv pip install -e ".[dev]"
cp .env.example .env
uvicorn src.main:app --reload
```

**Fullstack:**
```bash
cd my-project
docker-compose up -d
```

---

> 아래 섹션은 수동으로 프로젝트를 생성하거나, 스크립트 동작을 이해하기 위한 상세 가이드입니다.

---

## 2. Frontend 프로젝트 생성 (수동)

### 1.1 프로젝트 초기화

```bash
# 프로젝트 디렉토리 생성
mkdir my-frontend && cd my-frontend

# Vite + React + TypeScript 프로젝트 생성
pnpm create vite . --template react-ts

# 의존성 설치
pnpm install
```

### 1.2 표준 패키지 설치

```bash
# 회사 표준 패키지 설치 (npm registry 또는 로컬 경로)
pnpm add -D @company/eslint-config @company/prettier-config @company/typescript-config

# 필수 의존성
pnpm add react-router-dom zustand axios ag-grid-react ag-grid-community recharts

# 개발 의존성
pnpm add -D eslint prettier typescript @types/react @types/react-dom
```

> **로컬 개발 시**: 패키지가 npm에 배포되지 않은 경우
> ```bash
> # 상대 경로로 설치
> pnpm add -D ../dev-standards/packages/eslint-config
> pnpm add -D ../dev-standards/packages/prettier-config
> pnpm add -D ../dev-standards/packages/typescript-config
> ```

### 1.3 설정 파일 생성

**eslint.config.js**
```javascript
import config from '@company/eslint-config/react';

export default [
  ...config,
  {
    ignores: ['dist/', 'node_modules/', '*.config.js'],
  },
];
```

**prettier.config.js**
```javascript
import config from '@company/prettier-config';

export default {
  ...config,
};
```

**tsconfig.json**
```json
{
  "extends": "@company/typescript-config/react",
  "compilerOptions": {
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
```

**vite.config.ts**
```typescript
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
```

### 1.4 디렉토리 구조 생성

```bash
# 표준 디렉토리 구조 생성
mkdir -p src/{domains,shared/components/{DataGrid,Charts}}
mkdir -p .claude/{agents,commands}
mkdir -p docs/prd/{common,screens}
```

### 1.5 공통 컴포넌트 복사

```bash
# dev-standards에서 공통 컴포넌트 템플릿 복사 (필요시)
# 또는 frontend 레퍼런스 프로젝트에서 복사
cp -r ../frontend/src/shared/components/* src/shared/components/
```

### 1.6 Claude 설정 복사

```bash
# Agent 템플릿 복사
cp ../dev-standards/templates/claude-agents/react-specialist.md .claude/agents/
cp ../dev-standards/templates/claude-agents/code-quality-reviewer.md .claude/agents/

# Command 템플릿 복사 (필요시 수정)
cp ../frontend/.claude/commands/* .claude/commands/
```

### 1.7 OpenResty (Nginx + Lua) 설정

```bash
# Nginx 디렉토리 구조 생성
mkdir -p nginx/{conf.d,lua,ssl}

# 레퍼런스 프로젝트에서 복사
cp ../frontend/nginx/nginx.conf nginx/
cp ../frontend/nginx/conf.d/* nginx/conf.d/
cp ../frontend/nginx/lua/* nginx/lua/

# Docker 설정 복사
cp ../frontend/Dockerfile .
cp ../frontend/Dockerfile.dev .
cp ../frontend/docker-compose.yml .
cp ../frontend/docker-compose.prod.yml .
```

**OpenResty 구조:**
```
nginx/
├── nginx.conf           # 메인 설정
├── conf.d/
│   ├── default.conf     # 운영 서버 설정
│   └── dev.conf         # 개발 서버 설정
└── lua/
    ├── auth_check.lua   # 인증 체크
    ├── rate_limit.lua   # Rate Limiting
    └── cors.lua         # CORS 처리
```

### 1.8 CLAUDE.md 생성

```bash
# 레퍼런스 프로젝트에서 복사 후 프로젝트에 맞게 수정
cp ../frontend/CLAUDE.md .
# 프로젝트명, 설명 등 수정
```

### 1.9 package.json 스크립트 추가

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint src --ext ts,tsx",
    "lint:fix": "eslint src --ext ts,tsx --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,css}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,css}\"",
    "typecheck": "tsc --noEmit"
  }
}
```

---

## 3. Backend 프로젝트 생성 (수동)

### 2.1 프로젝트 초기화

```bash
# 프로젝트 디렉토리 생성
mkdir my-backend && cd my-backend

# Python 가상환경 생성 (uv 사용 권장)
uv venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
```

### 2.2 pyproject.toml 생성

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-backend"
version = "0.1.0"
description = "My FastAPI Backend"
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
    "company-python-standards>=1.0.0",
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "httpx>=0.27.0",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "ARG", "SIM", "TCH", "PTH", "ERA", "PL", "RUF", "ASYNC", "S"]
ignore = ["E501", "PLR0913", "PLR2004"]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["S101", "ARG"]

[tool.mypy]
python_version = "3.11"
strict = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

### 2.3 의존성 설치

```bash
# 기본 의존성 설치
uv pip install -e .

# 개발 의존성 설치
uv pip install -e ".[dev]"

# 회사 표준 패키지 설치 (로컬 경로)
uv pip install -e ../dev-standards/packages/python-standards
```

### 2.4 디렉토리 구조 생성

```bash
# 표준 디렉토리 구조 생성
mkdir -p src/{domains,shared/{database,utils}}
mkdir -p .claude/{agents,commands}
mkdir -p docs/prd/{common,endpoints}
mkdir -p tests/{unit,integration}

# __init__.py 파일 생성
touch src/__init__.py
touch src/domains/__init__.py
touch src/shared/__init__.py
touch src/shared/database/__init__.py
touch src/shared/utils/__init__.py
```

### 2.5 공통 모듈 복사

```bash
# 레퍼런스 프로젝트에서 공통 모듈 복사
cp ../backend/src/shared/database/connection.py src/shared/database/
cp ../backend/src/shared/database/transaction.py src/shared/database/
cp ../backend/src/shared/utils/sql_loader.py src/shared/utils/

# __init__.py 복사
cp ../backend/src/shared/database/__init__.py src/shared/database/
cp ../backend/src/shared/utils/__init__.py src/shared/utils/
```

### 2.6 메인 앱 파일 생성

**src/main.py**
```python
from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.shared.database import db_pool


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    await db_pool.initialize()
    yield
    await db_pool.close()


app = FastAPI(
    title="My Backend API",
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
    return {"status": "healthy"}
```

### 2.7 Claude 설정 복사

```bash
# Agent 템플릿 복사
cp ../dev-standards/templates/claude-agents/fastapi-specialist.md .claude/agents/
cp ../dev-standards/templates/claude-agents/sql-query-specialist.md .claude/agents/

# Command 템플릿 복사
cp ../backend/.claude/commands/* .claude/commands/
```

### 2.8 CLAUDE.md 생성

```bash
cp ../backend/CLAUDE.md .
# 프로젝트에 맞게 수정
```

### 2.9 환경 변수 파일 생성

**.env.example**
```bash
DB_PRIMARY_DB_URL=postgresql://user:password@localhost:5432/mydb
DB_REPLICA_DB_URL=
```

---

## 4. 새 도메인 추가하기

### 3.1 Frontend 도메인 추가

```bash
# 도메인 디렉토리 구조 생성
mkdir -p src/domains/users/{components,hooks,stores,pages,api,types}
```

필요한 파일:
- `types/index.ts` - 타입 정의
- `api/usersApi.ts` - API 호출 함수
- `stores/usersStore.ts` - Zustand 스토어
- `components/` - 컴포넌트들
- `pages/` - 페이지 컴포넌트

### 3.2 Backend 도메인 추가

```bash
# 도메인 디렉토리 구조 생성
mkdir -p src/domains/users/sql/{queries,commands}
touch src/domains/users/__init__.py
```

필요한 파일:
- `schemas.py` - Pydantic 스키마
- `repository.py` - 데이터 접근 레이어
- `service.py` - 비즈니스 로직
- `router.py` - API 엔드포인트
- `sql/queries/` - SELECT 쿼리
- `sql/commands/` - INSERT/UPDATE/DELETE 쿼리

```python
# src/main.py에 라우터 등록
from src.domains.users import router as users_router
app.include_router(users_router)
```

---

## 5. 체크리스트

### Frontend 프로젝트 생성 체크리스트
- [ ] Vite + React + TypeScript 초기화
- [ ] 표준 패키지 설치 (@company/eslint-config, prettier-config, typescript-config)
- [ ] 설정 파일 생성 (eslint, prettier, tsconfig, vite)
- [ ] 디렉토리 구조 생성 (domains, shared, .claude)
- [ ] 공통 컴포넌트 복사 (DataGrid, Charts)
- [ ] Claude agents/commands 복사
- [ ] **Hooks 설정 (환경 버전 강제)**
  - [ ] `.claude/settings.json` 복사
  - [ ] `.claude/scripts/check-env.sh` 복사 및 실행 권한 부여
  - [ ] `.node-version`, `.nvmrc` 파일 생성
- [ ] **OpenResty 설정**
  - [ ] `nginx/` 디렉토리 구조 복사
  - [ ] `Dockerfile`, `Dockerfile.dev` 복사
  - [ ] `docker-compose.yml` 복사 및 수정
- [ ] CLAUDE.md 생성 및 수정
- [ ] package.json 스크립트 추가
- [ ] lint/format 실행 확인

### Backend 프로젝트 생성 체크리스트
- [ ] Python 가상환경 생성
- [ ] pyproject.toml 생성
- [ ] 의존성 설치
- [ ] 디렉토리 구조 생성 (domains, shared, tests)
- [ ] 공통 모듈 복사 (database, utils)
- [ ] main.py 생성
- [ ] Claude agents/commands 복사
- [ ] **Hooks 설정 (환경 버전 강제)**
  - [ ] `.claude/settings.json` 복사
  - [ ] `.claude/scripts/check-env.sh` 복사 및 실행 권한 부여
  - [ ] `.python-version` 파일 생성
- [ ] CLAUDE.md 생성 및 수정
- [ ] .env.example 생성
- [ ] ruff/mypy 실행 확인

---

## 6. 레거시 스크립트 (참고용)

> **주의**: 아래 스크립트들은 참고용입니다. 실제 프로젝트 생성 시에는 **섹션 0의 통합 스크립트** (`scripts/create-project.sh`)를 사용하세요.

### create-frontend.sh (레거시)
```bash
#!/bin/bash
PROJECT_NAME=$1
STANDARDS_PATH="../dev-standards"
REFERENCE_PATH="../frontend"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: ./create-frontend.sh <project-name>"
  exit 1
fi

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

# Vite 프로젝트 생성
pnpm create vite . --template react-ts

# 디렉토리 구조
mkdir -p src/{domains,shared/components/{DataGrid,Charts}}
mkdir -p .claude/{agents,commands}
mkdir -p docs/prd/{common,screens}

# 공통 파일 복사
cp -r $REFERENCE_PATH/src/shared/components/* src/shared/components/
cp $REFERENCE_PATH/eslint.config.js .
cp $REFERENCE_PATH/prettier.config.js .
cp $REFERENCE_PATH/tsconfig.json .
cp $REFERENCE_PATH/vite.config.ts .
cp $REFERENCE_PATH/CLAUDE.md .

# Claude 설정 복사
cp $STANDARDS_PATH/templates/claude-agents/react-specialist.md .claude/agents/
cp $STANDARDS_PATH/templates/claude-agents/code-quality-reviewer.md .claude/agents/
cp $REFERENCE_PATH/.claude/commands/* .claude/commands/

# Hooks 설정 (환경 버전 강제)
mkdir -p .claude/scripts
cp $STANDARDS_PATH/templates/hooks/frontend/settings.json .claude/
cp $STANDARDS_PATH/templates/hooks/frontend/check-env.sh .claude/scripts/
chmod +x .claude/scripts/check-env.sh
echo "20" > .node-version
echo "20" > .nvmrc

# OpenResty 설정 복사
mkdir -p nginx/{conf.d,lua,ssl}
cp $REFERENCE_PATH/nginx/nginx.conf nginx/
cp $REFERENCE_PATH/nginx/conf.d/* nginx/conf.d/
cp $REFERENCE_PATH/nginx/lua/* nginx/lua/
cp $REFERENCE_PATH/Dockerfile .
cp $REFERENCE_PATH/Dockerfile.dev .
cp $REFERENCE_PATH/docker-compose.yml .
cp $REFERENCE_PATH/docker-compose.prod.yml .

echo "Frontend project '$PROJECT_NAME' created!"
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  pnpm install"
echo "  pnpm dev"
echo ""
echo "Docker (with OpenResty):"
echo "  docker-compose up -d"
```

### create-backend.sh (레거시)
```bash
#!/bin/bash
PROJECT_NAME=$1
STANDARDS_PATH="../dev-standards"
REFERENCE_PATH="../backend"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: ./create-backend.sh <project-name>"
  exit 1
fi

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

# 디렉토리 구조
mkdir -p src/{domains,shared/{database,utils}}
mkdir -p .claude/{agents,commands}
mkdir -p docs/prd/{common,endpoints}
mkdir -p tests/{unit,integration}

# __init__.py 생성
touch src/__init__.py src/domains/__init__.py src/shared/__init__.py
touch src/shared/database/__init__.py src/shared/utils/__init__.py

# 공통 파일 복사
cp $REFERENCE_PATH/pyproject.toml .
cp $REFERENCE_PATH/src/main.py src/
cp -r $REFERENCE_PATH/src/shared/database/* src/shared/database/
cp -r $REFERENCE_PATH/src/shared/utils/* src/shared/utils/
cp $REFERENCE_PATH/CLAUDE.md .

# Claude 설정 복사
cp $STANDARDS_PATH/templates/claude-agents/fastapi-specialist.md .claude/agents/
cp $STANDARDS_PATH/templates/claude-agents/sql-query-specialist.md .claude/agents/
cp $REFERENCE_PATH/.claude/commands/* .claude/commands/

# Hooks 설정 (환경 버전 강제)
mkdir -p .claude/scripts
cp $STANDARDS_PATH/templates/hooks/backend/settings.json .claude/
cp $STANDARDS_PATH/templates/hooks/backend/check-env.sh .claude/scripts/
chmod +x .claude/scripts/check-env.sh
echo "3.11" > .python-version

# 환경 변수 예시
echo "DB_PRIMARY_DB_URL=postgresql://user:password@localhost:5432/$PROJECT_NAME" > .env.example

echo "Backend project '$PROJECT_NAME' created!"
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  uv venv && source .venv/bin/activate"
echo "  uv pip install -e '.[dev]'"
echo "  uvicorn src.main:app --reload"
```

사용법:
```bash
chmod +x create-frontend.sh create-backend.sh

./create-frontend.sh my-new-frontend
./create-backend.sh my-new-backend
```
