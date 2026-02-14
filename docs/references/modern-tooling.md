# 모던 개발 도구 참조

## 패키지 매니저

### pnpm (Node.js)
```bash
# 프로젝트 초기화
pnpm init

# 의존성 설치
pnpm add react react-dom
pnpm add -D typescript @types/react

# 스크립트 실행
pnpm dev
pnpm build

# 워크스페이스 (모노레포)
pnpm -F @app/web dev
pnpm -F @app/api test
```

### uv (Python)
```bash
# 프로젝트 초기화
uv init my-project
cd my-project

# 의존성 추가
uv add fastapi uvicorn
uv add --dev pytest ruff mypy

# 스크립트 실행
uv run python main.py
uv run pytest
uv run ruff check .

# 가상환경 동기화
uv sync
```

## 빌드 도구

### Vite (프론트엔드)
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': '/src' },
  },
  server: {
    proxy: {
      '/api': 'http://localhost:8000',
    },
  },
});
```

### tsup (라이브러리)
```typescript
// tsup.config.ts
import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs', 'esm'],
  dts: true,
  clean: true,
  splitting: true,
});
```

## 린팅/포맷팅

### ESLint Flat Config
```javascript
// eslint.config.js
import js from '@eslint/js';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import reactPlugin from 'eslint-plugin-react';

export default [
  js.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsParser,
      parserOptions: { project: './tsconfig.json' },
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      react: reactPlugin,
    },
    rules: {
      '@typescript-eslint/no-unused-vars': 'error',
      'react/react-in-jsx-scope': 'off',
    },
  },
  {
    ignores: ['dist/', 'node_modules/'],
  },
];
```

### Ruff (Python)
```toml
# pyproject.toml
[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "N",    # pep8-naming
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "SIM",  # flake8-simplify
]
ignore = ["E501"]

[tool.ruff.lint.isort]
known-first-party = ["src"]
```

### Biome (JS/TS 올인원)
```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2
  }
}
```

## 프로젝트 구조 권장안

### FastAPI 프로젝트
```
my-api/
├── pyproject.toml
├── src/
│   └── my_api/
│       ├── __init__.py
│       ├── main.py              # FastAPI app 생성, 라우터 등록
│       ├── config.py            # Settings (pydantic-settings)
│       ├── dependencies.py      # 공유 의존성 (DB 세션 등)
│       ├── routers/
│       │   ├── __init__.py
│       │   ├── users.py
│       │   └── items.py
│       ├── schemas/
│       │   ├── __init__.py
│       │   ├── users.py
│       │   └── items.py
│       ├── models/              # SQLAlchemy 모델
│       │   ├── __init__.py
│       │   └── base.py
│       └── services/            # 비즈니스 로직
│           ├── __init__.py
│           └── users.py
├── tests/
│   ├── conftest.py
│   ├── test_users.py
│   └── test_items.py
└── alembic/                     # DB 마이그레이션
    └── versions/
```

### React/Next.js 프로젝트
```
my-app/
├── package.json
├── tsconfig.json
├── next.config.ts
├── src/
│   ├── app/                     # Next.js App Router
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── (routes)/
│   │       ├── dashboard/
│   │       │   └── page.tsx
│   │       └── settings/
│   │           └── page.tsx
│   ├── components/
│   │   ├── ui/                  # 재사용 UI 컴포넌트
│   │   │   ├── Button/
│   │   │   └── Input/
│   │   └── features/            # 기능별 컴포넌트
│   │       ├── UserProfile/
│   │       └── Dashboard/
│   ├── hooks/                   # 커스텀 훅
│   ├── lib/                     # 유틸리티, API 클라이언트
│   ├── stores/                  # 상태 관리 (Zustand)
│   └── types/                   # 타입 정의
├── public/
└── __tests__/
```

## Docker 멀티스테이지 빌드

### Python (FastAPI)
```dockerfile
# Build stage
FROM python:3.12-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src/ src/
RUN uv sync --frozen --no-dev

# Runtime stage
FROM python:3.12-slim

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000

CMD ["uvicorn", "src.my_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### TypeScript (Next.js)
```dockerfile
# Dependencies stage
FROM node:22-slim AS deps
RUN corepack enable pnpm
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Build stage
FROM node:22-slim AS builder
RUN corepack enable pnpm
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

# Runtime stage
FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
```
