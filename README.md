# Dev Standards

팀 개발 표준을 정의하는 저장소입니다.

## 개요

이 저장소는 Frontend/Backend 프로젝트에서 공통으로 사용하는 개발 표준을 관리합니다.

- **Linting/Formatting**: ESLint, Prettier, Ruff 설정
- **TypeScript**: 타입스크립트 설정
- **Claude Code**: Agent 템플릿, 커스텀 명령어
- **Workflow**: 개발 워크플로우, Git 전략

> **💡 처음 사용하시나요?** [5분 Quick Start 가이드](QUICKSTART.md)를 먼저 확인하세요!

## Quick Start

### 1. 새 프로젝트 생성

통합 스크립트로 Frontend, Backend, 또는 Fullstack 프로젝트를 빠르게 생성할 수 있습니다.

```bash
# dev-standards 저장소 클론
git clone <repository-url> dev-standards
cd dev-standards

# Fullstack 프로젝트 생성 (Frontend + Backend)
./scripts/create-project.sh --name my-project --type fullstack

# Frontend만 생성
./scripts/create-project.sh --name my-app --type frontend

# Backend만 생성
./scripts/create-project.sh --name my-api --type backend

# 대화형 모드 (옵션 선택)
./scripts/create-project.sh
```

생성되는 항목: 디렉토리 구조, 설정 파일(ESLint, Prettier, TypeScript/Ruff), Docker 설정, Claude Code Agent, CLAUDE.md, 개발 표준 문서

### 2. 기존 프로젝트에 적용

이미 존재하는 프로젝트에 개발 표준을 적용하려면 필요한 패키지만 설치합니다.

**Frontend (npm)**
```bash
# 패키지 설치
pnpm add -D @company/eslint-config @company/prettier-config @company/typescript-config

# eslint.config.js
import config from '@company/eslint-config/react';
export default config;

# prettier.config.js
import config from '@company/prettier-config';
export default config;

# tsconfig.json
{ "extends": "@company/typescript-config/react" }
```

**Backend (pip)**
```bash
# 패키지 설치
uv pip install company-python-standards

# pyproject.toml에 ruff 설정 추가
[tool.ruff]
extend = "./path/to/company_standards/ruff.toml"
```

### 3. Claude Code Agent 활용

프로젝트에 Agent 템플릿을 복사하여 Claude Code의 전문 Agent를 활용할 수 있습니다.

```bash
# Frontend 프로젝트
cp templates/claude-agents/react-specialist.md <project>/.claude/agents/
cp templates/claude-agents/e2e-test-specialist.md <project>/.claude/agents/

# Backend 프로젝트
cp templates/claude-agents/fastapi-specialist.md <project>/.claude/agents/
cp templates/claude-agents/sql-query-specialist.md <project>/.claude/agents/

# Fullstack Team (병렬 개발)
cp templates/claude-teams/fullstack-team.md <project>/.claude/agents/
```

사용 예시:
```bash
@react-specialist 매출 차트 컴포넌트 구현
@fastapi-specialist 매출 조회 API 구현
@fullstack-team 매출 목록 페이지 구현   # 5명이 병렬 작업
```

### 4. 도움말

| 주제 | 문서 |
|------|------|
| 프로젝트 생성 상세 | [New Project Setup](templates/workflows/new-project-setup.md) |
| 개발 워크플로우 | [Development Workflow](templates/workflows/development-workflow.md) |
| Fullstack Team 가이드 | [Fullstack Team Guide](templates/workflows/fullstack-team-guide.md) |
| Git 브랜치 전략 | [Git Workflow](docs/git-workflow.md) |
| 커밋 컨벤션 | [Commit Convention](docs/commit-convention.md) |
| Claude Hooks | [Claude Hooks Guide](docs/claude-hooks.md) |

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
│   ├── claude-teams/           # Claude Code Team 템플릿
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

### Team Template

| Team | 구성 | 역할 |
|------|-----|------|
| `fullstack-team` | Lead + 5 specialists | Fullstack 기능 병렬 개발 |

여러 전문 에이전트가 Phase별로 병렬 작업하여 Backend, SQL, Frontend, Test, Review를 체계적으로 수행합니다.

## Git 워크플로우

```
master (production)
   └── SKTL-XXXX (작업 브랜치)
         └── develop (테스트)
```

- 브랜치명: `SKTL-XXXX` (JIRA 티켓 ID)
- 로컬에서 master push/merge 금지
- GitHub PR을 통해서만 master 병합

## 문서

- [Git Workflow](docs/git-workflow.md)
- [Commit Convention](docs/commit-convention.md)
- [Claude Hooks Guide](docs/claude-hooks.md)
- [Development Workflow](templates/workflows/development-workflow.md)
- [Fullstack Team Guide](templates/workflows/fullstack-team-guide.md)
- [New Project Setup](templates/workflows/new-project-setup.md)

## 기여

1. 변경사항은 PR로 제출
2. 팀 리뷰 후 병합
3. 모든 프로젝트에 영향을 미치므로 신중하게 결정
# dev-standards
