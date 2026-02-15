# Migration Guide

기존 프로젝트에 dev-standards를 적용하기 위한 단계별 가이드입니다.

---

## 목차

1. [Frontend 마이그레이션](#1-frontend-마이그레이션)
2. [Backend 마이그레이션](#2-backend-마이그레이션)
3. [Fullstack 마이그레이션](#3-fullstack-마이그레이션)
4. [패키지 버전 업그레이드](#4-패키지-버전-업그레이드)
5. [롤백 절차](#5-롤백-절차)

---

## 1. Frontend 마이그레이션

### 사전 요구사항

- Node.js >= 18.0.0
- pnpm >= 8.0.0
- ESLint >= 9.0.0 (Flat Config 지원)

### Step 1: 기존 설정 백업

```bash
# 기존 설정 파일 백업
mkdir -p .backup
cp .eslintrc* .backup/ 2>/dev/null || true
cp .prettierrc* .backup/ 2>/dev/null || true
cp tsconfig.json .backup/ 2>/dev/null || true
```

### Step 2: 패키지 설치

```bash
# 기존 ESLint 관련 패키지 제거
pnpm remove eslint-config-* eslint-plugin-* @typescript-eslint/*

# dev-standards 패키지 설치
pnpm add -D @company/eslint-config @company/prettier-config @company/typescript-config
```

### Step 3: ESLint 설정 전환

```bash
# 기존 .eslintrc* 삭제
rm -f .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml
```

```javascript
// eslint.config.js (새로 생성)
import config from '@company/eslint-config/react';

export default [
  ...config,
  // 프로젝트별 추가 규칙
  {
    rules: {
      // 필요한 경우 규칙 오버라이드
    },
  },
];
```

### Step 4: Prettier 설정 전환

```bash
# 기존 .prettierrc* 삭제
rm -f .prettierrc .prettierrc.js .prettierrc.json .prettierrc.yml
```

```javascript
// prettier.config.js (새로 생성)
import config from '@company/prettier-config';
export default config;
```

### Step 5: TypeScript 설정 전환

```json
// tsconfig.json
{
  "extends": "@company/typescript-config/react",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Step 6: Commitlint 설정

```bash
# commitlint + husky 설치
pnpm add -D @commitlint/cli @commitlint/config-conventional husky

# husky 초기화
npx husky init

# commit-msg hook 설정
echo 'npx --no -- commitlint --edit "$1"' > .husky/commit-msg
chmod +x .husky/commit-msg
```

```javascript
// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2, 'always',
      ['feat', 'fix', 'docs', 'style', 'refactor',
       'perf', 'test', 'chore', 'ci', 'revert']
    ],
    'subject-max-length': [2, 'always', 50],
    'header-max-length': [2, 'always', 72],
  },
};
```

### Step 7: 검증

```bash
# ESLint 실행 (에러 확인)
pnpm eslint src/ --max-warnings 0

# TypeScript 타입 체크
pnpm tsc --noEmit

# Prettier 포맷 체크
pnpm prettier --check "src/**/*.{ts,tsx}"

# 포맷 자동 수정
pnpm prettier --write "src/**/*.{ts,tsx}"
pnpm eslint src/ --fix
```

### 예상 이슈 및 해결

| 이슈 | 해결 방법 |
|------|----------|
| `import type` 에러 | `verbatimModuleSyntax` 활성화됨. `import type { X }` 사용 |
| path alias 에러 | `tsconfig.json` + `vite.config.ts` 모두 설정 필요 |
| ESLint 규칙 충돌 | 커스텀 규칙은 config 배열 마지막에 추가 |

---

## 2. Backend 마이그레이션

### 사전 요구사항

- Python >= 3.11
- uv (패키지 매니저)
- PostgreSQL (로컬 또는 Docker)

### Step 1: 기존 설정 백업

```bash
mkdir -p .backup
cp pyproject.toml .backup/ 2>/dev/null || true
cp setup.cfg .backup/ 2>/dev/null || true
cp .flake8 .backup/ 2>/dev/null || true
cp .isort.cfg .backup/ 2>/dev/null || true
```

### Step 2: uv 설치 (미설치 시)

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.zshrc  # 또는 source ~/.bashrc
```

### Step 3: 패키지 설치

```bash
# 기존 린터 제거
uv pip uninstall flake8 black isort pylint 2>/dev/null || true

# dev-standards 패키지 설치
uv pip install company-python-standards
```

### Step 4: Ruff 설정 전환

기존 flake8/black/isort 설정을 ruff로 전환합니다.

```bash
# 기존 설정 파일 삭제
rm -f .flake8 .isort.cfg .black.toml
```

```toml
# pyproject.toml 에 추가
[tool.ruff]
extend = "./path/to/company_standards/ruff.toml"
target-version = "py311"
line-length = 120

[tool.ruff.lint]
# 프로젝트별 추가 규칙
extend-select = []
extend-ignore = []

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### Step 5: mypy 설정 전환

```toml
# pyproject.toml 에 추가
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

[[tool.mypy.overrides]]
module = ["tests.*"]
disallow_untyped_defs = false
```

### Step 6: Commitlint 설정

```bash
# git hooks 디렉토리 생성
mkdir -p .githooks

# commit-msg hook 설정 (dev-standards 템플릿 사용)
cp path/to/dev-standards/templates/git/commit-msg-hook.sh .githooks/commit-msg
chmod +x .githooks/commit-msg

# git hooks 경로 설정
git config core.hooksPath .githooks
```

### Step 7: 검증

```bash
# Ruff 린트 실행
ruff check src/

# Ruff 포맷 체크
ruff format --check src/

# mypy 타입 체크
mypy src/

# 자동 수정
ruff check src/ --fix
ruff format src/
```

### 기존 도구 → Ruff 매핑

| 기존 도구 | Ruff 대체 | 비고 |
|-----------|----------|------|
| flake8 | `ruff check` | 대부분의 규칙 호환 |
| black | `ruff format` | black 호환 포맷터 |
| isort | `ruff check --select I` | import 정렬 내장 |
| pylint | `ruff check --select PL` | 일부 규칙 호환 |

---

## 3. Fullstack 마이그레이션

Frontend + Backend를 동시에 마이그레이션하는 경우입니다.

### 권장 순서

1. **Backend 먼저** - API 변경이 없으므로 안전하게 진행
2. **Frontend 다음** - Backend 안정 후 진행
3. **통합 테스트** - 전체 파이프라인 검증

### Step 1: 프로젝트 구조 확인

```
my-project/
├── frontend/          # Frontend 마이그레이션 (섹션 1)
├── backend/           # Backend 마이그레이션 (섹션 2)
├── docker-compose.yml
└── .github/
    └── workflows/
```

### Step 2: Backend 마이그레이션

[Backend 마이그레이션](#2-backend-마이그레이션) 섹션을 따라 진행합니다.

### Step 3: Frontend 마이그레이션

[Frontend 마이그레이션](#1-frontend-마이그레이션) 섹션을 따라 진행합니다.

### Step 4: Claude Agent 설정

```bash
# Agent 템플릿 복사
mkdir -p .claude/agents
cp path/to/dev-standards/templates/claude-agents/react-specialist.md .claude/agents/
cp path/to/dev-standards/templates/claude-agents/fastapi-specialist.md .claude/agents/
cp path/to/dev-standards/templates/claude-agents/sql-query-specialist.md .claude/agents/
cp path/to/dev-standards/templates/claude-agents/api-test-specialist.md .claude/agents/
cp path/to/dev-standards/templates/claude-agents/code-quality-reviewer.md .claude/agents/

# Team 템플릿 (선택)
cp path/to/dev-standards/templates/claude-teams/fullstack-team.md .claude/agents/
```

### Step 5: CI/CD 설정

```yaml
# .github/workflows/ci.yml 업데이트 예시
name: CI

on:
  push:
    branches: [master, main]
  pull_request:

jobs:
  frontend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
          cache-dependency-path: frontend/pnpm-lock.yaml
      - run: pnpm install
      - run: pnpm eslint src/
      - run: pnpm tsc --noEmit
      - run: pnpm prettier --check "src/**/*.{ts,tsx}"

  backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install uv && uv pip install -r requirements.txt
      - run: ruff check src/
      - run: ruff format --check src/
      - run: mypy src/
```

---

## 4. 패키지 버전 업그레이드

### Minor/Patch 업그레이드

```bash
# Frontend
pnpm update @company/eslint-config @company/prettier-config @company/typescript-config

# Backend
uv pip install --upgrade company-python-standards
```

### Major 업그레이드

Major 업그레이드는 Breaking Change가 포함될 수 있으므로 각 패키지의 CHANGELOG를 확인하세요.

```bash
# 1. CHANGELOG 확인
# packages/eslint-config/CHANGELOG.md 에서 BREAKING CHANGE 섹션 확인

# 2. 업그레이드
pnpm add -D @company/eslint-config@latest

# 3. 변경사항 적용
pnpm eslint src/ --fix  # 새 규칙에 맞게 자동 수정

# 4. 수동 수정이 필요한 항목 확인
pnpm eslint src/
```

---

## 5. 롤백 절차

마이그레이션 실패 시 백업에서 복원합니다.

### Frontend 롤백

```bash
# 1. dev-standards 패키지 제거
pnpm remove @company/eslint-config @company/prettier-config @company/typescript-config

# 2. 백업에서 복원
cp .backup/.eslintrc* ./ 2>/dev/null || true
cp .backup/.prettierrc* ./ 2>/dev/null || true
cp .backup/tsconfig.json ./ 2>/dev/null || true

# 3. 기존 패키지 재설치
pnpm install

# 4. 새 설정 파일 제거
rm -f eslint.config.js prettier.config.js
```

### Backend 롤백

```bash
# 1. dev-standards 패키지 제거
uv pip uninstall company-python-standards

# 2. 백업에서 복원
cp .backup/pyproject.toml ./ 2>/dev/null || true
cp .backup/.flake8 ./ 2>/dev/null || true
cp .backup/.isort.cfg ./ 2>/dev/null || true

# 3. 기존 패키지 재설치
uv pip install -r requirements.txt
```

---

## 체크리스트

### Frontend 마이그레이션 완료 체크리스트

- [ ] `@company/eslint-config` 설치 완료
- [ ] `@company/prettier-config` 설치 완료
- [ ] `@company/typescript-config` 설치 완료
- [ ] `eslint.config.js` 생성 완료
- [ ] `prettier.config.js` 생성 완료
- [ ] `tsconfig.json` extends 설정 완료
- [ ] commitlint + husky 설정 완료
- [ ] `pnpm eslint src/` 통과
- [ ] `pnpm tsc --noEmit` 통과
- [ ] `pnpm prettier --check` 통과
- [ ] 기존 `.eslintrc*`, `.prettierrc*` 삭제 완료

### Backend 마이그레이션 완료 체크리스트

- [ ] `company-python-standards` 설치 완료
- [ ] `ruff.toml` extend 설정 완료
- [ ] mypy 설정 완료
- [ ] commitlint hook 설정 완료
- [ ] `ruff check src/` 통과
- [ ] `ruff format --check src/` 통과
- [ ] `mypy src/` 통과
- [ ] 기존 `.flake8`, `.isort.cfg` 삭제 완료
