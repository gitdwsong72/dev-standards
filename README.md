# Dev Standards

팀 개발 표준을 정의하는 저장소입니다.

## 개요

이 저장소는 Frontend/Backend 프로젝트에서 공통으로 사용하는 개발 표준을 관리합니다.

- **Linting/Formatting**: ESLint, Prettier, Ruff 설정
- **TypeScript**: 타입스크립트 설정
- **Claude Code**: Agent 템플릿, 커스텀 명령어
- **Workflow**: 개발 워크플로우, Git 전략

## 패키지

### Frontend (npm)

```bash
# ESLint 설정
pnpm add -D @company/eslint-config

# Prettier 설정
pnpm add -D @company/prettier-config

# TypeScript 설정
pnpm add -D @company/typescript-config
```

### Backend (pip)

```bash
# Python 표준 (Ruff, mypy)
uv pip install company-python-standards
```

## 구조

```
dev-standards/
├── packages/
│   ├── eslint-config/          # @company/eslint-config
│   ├── prettier-config/        # @company/prettier-config
│   ├── typescript-config/      # @company/typescript-config
│   └── python-standards/       # company-python-standards
├── templates/
│   ├── claude-agents/          # Claude Code Agent 템플릿
│   ├── prd/                    # PRD 템플릿
│   ├── hooks/                  # 환경 체크 Hook
│   └── workflows/              # 워크플로우 문서
└── docs/
    ├── git-workflow.md         # Git 브랜치 전략
    ├── commit-convention.md    # 커밋 컨벤션
    └── claude-hooks.md         # Claude Code Hooks 가이드
```

## 사용법

### ESLint 설정 (React 프로젝트)

```javascript
// eslint.config.js
import config from '@company/eslint-config/react';
export default config;
```

### Prettier 설정

```javascript
// prettier.config.js
import config from '@company/prettier-config';
export default config;
```

### TypeScript 설정

```json
// tsconfig.json
{
  "extends": "@company/typescript-config/react"
}
```

### Python Ruff 설정

```toml
# pyproject.toml
[tool.ruff]
extend = "./path/to/company_standards/ruff.toml"
```

## Claude Code Agent

| Agent | 용도 | 대상 |
|-------|------|------|
| react-specialist | React, AG-Grid, Zustand | Frontend |
| fastapi-specialist | FastAPI, API 설계 | Backend |
| sql-query-specialist | PostgreSQL 쿼리 | Backend |
| code-quality-reviewer | 코드 품질 리뷰 | 공통 |
| e2e-test-specialist | Playwright E2E | Frontend |
| api-test-specialist | pytest API 테스트 | Backend |

## Git 워크플로우

```
master (production)
   └── SKTL-XXXX (작업 브랜치)
         └── develop (테스트)
```

- 브랜치명: `SKTL-XXXX` (JIRA 티켓 ID)
- 로컬에서 master push/merge 금지
- GitLab MR을 통해서만 master 병합

## 문서

- [Git Workflow](docs/git-workflow.md)
- [Commit Convention](docs/commit-convention.md)
- [Claude Hooks Guide](docs/claude-hooks.md)
- [Development Workflow](templates/workflows/development-workflow.md)
- [New Project Setup](templates/workflows/new-project-setup.md)

## 기여

1. 변경사항은 PR로 제출
2. 팀 리뷰 후 병합
3. 모든 프로젝트에 영향을 미치므로 신중하게 결정
