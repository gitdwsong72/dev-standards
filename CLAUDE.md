# CLAUDE.md - dev-standards

## 프로젝트 개요
팀 개발 표준을 정의하는 저장소입니다. ESLint, Prettier, TypeScript, Python 표준 설정과 Claude Code Agent 템플릿, PRD 템플릿을 제공합니다.

> **💡 빠른 시작:** 처음 사용하시는 분은 [QUICKSTART.md](QUICKSTART.md)를 먼저 읽어보세요 (5분 완주 가능)

## 구조

```
dev-standards/
├── packages/
│   ├── eslint-config/          # @company/eslint-config (npm)
│   ├── prettier-config/        # @company/prettier-config (npm)
│   ├── typescript-config/      # @company/typescript-config (npm)
│   └── python-standards/       # company-python-standards (pip)
├── templates/
│   ├── claude-agents/          # Agent 템플릿
│   ├── claude-teams/           # Team 템플릿
│   ├── claude-skills/          # Claude Skills 템플릿
│   │   ├── dev-toolkit/        # 코드 생성 도구 스킬
│   │   ├── manage-skills/      # 검증 스킬 자동 관리
│   │   └── verify-implementation/ # 통합 검증 실행
│   ├── code-generators/        # 코드 생성 템플릿 (11개)
│   ├── prd/                    # PRD 템플릿
│   ├── hooks/                  # Claude Hooks 템플릿
│   └── workflows/              # 워크플로우 문서
├── scripts/
│   ├── create-project.sh       # 신규 프로젝트 생성 스크립트
│   └── generators/             # 코드 생성기 (Python)
│       ├── generate_api.py     # API 엔드포인트 생성
│       ├── generate_component.py # UI 컴포넌트 생성
│       └── generate_test.py    # 테스트 파일 생성
└── docs/
    ├── references/             # 기술 참조 문서
    │   ├── coding-patterns.md  # Python/TS 코딩 패턴
    │   ├── git-workflows.md    # Git/CI/CD 가이드
    │   └── modern-tooling.md   # 모던 개발 도구
    ├── code-generators-guide.md # 코드 생성기 사용 가이드
    ├── claude-skills-guide.md  # Claude Skills 사용 가이드
    ├── git-workflow.md
    └── commit-convention.md
```

## 신규 프로젝트 생성

통합 스크립트를 사용하여 새 프로젝트를 빠르게 생성할 수 있습니다.

```bash
# 대화형 모드
./scripts/create-project.sh

# 명령줄 인자 사용
./scripts/create-project.sh --name my-project --type fullstack
./scripts/create-project.sh -n my-app -t frontend
./scripts/create-project.sh -n api-server -t backend
```

자세한 내용은 `templates/workflows/new-project-setup.md` 참조

## 패키지 사용법

### Frontend (npm)
```bash
# 설치
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

### Backend (pip)
```bash
# 설치
uv pip install company-python-standards

# pyproject.toml에서 ruff 설정 상속
[tool.ruff]
extend = "path/to/company_standards/ruff.toml"
```

## 표준 업데이트

### 버전 관리
- Semantic Versioning 사용
- Major: 호환성 깨지는 변경
- Minor: 새 규칙 추가
- Patch: 버그 수정

### 배포 프로세스
1. 변경사항 커밋
2. 버전 업데이트
3. CHANGELOG 작성
4. 패키지 배포

## Claude Code Agent 가이드

### 사용 가능한 Agent 템플릿
| Agent | 대상 | 역할 |
|-------|------|------|
| `react-specialist` | Frontend | React, AG-Grid, Recharts, Zustand 전문 |
| `e2e-test-specialist` | Frontend | Playwright E2E 테스트 전문 |
| `fastapi-specialist` | Backend | FastAPI API 설계 전문 |
| `sql-query-specialist` | Backend | PostgreSQL 쿼리 전문 |
| `api-test-specialist` | Backend | pytest + httpx API 테스트 전문 |
| `code-quality-reviewer` | 공통 | 코드 품질/보안 리뷰 |

### 템플릿 복사 방법
```bash
# Frontend 프로젝트
cp templates/claude-agents/react-specialist.md ../frontend/.claude/agents/
cp templates/claude-agents/e2e-test-specialist.md ../frontend/.claude/agents/
cp templates/claude-agents/code-quality-reviewer.md ../frontend/.claude/agents/

# Backend 프로젝트
cp templates/claude-agents/fastapi-specialist.md ../backend/.claude/agents/
cp templates/claude-agents/sql-query-specialist.md ../backend/.claude/agents/
cp templates/claude-agents/api-test-specialist.md ../backend/.claude/agents/
```

## Claude Code Team 가이드

### Fullstack Team
여러 전문 에이전트가 병렬로 작업하는 팀 구성 템플릿입니다.

| Team | 구성 | 역할 |
|------|-----|------|
| `fullstack-team` | Lead + 5 specialists | Fullstack 기능 병렬 개발 |

**팀 구성:**
| Teammate | Agent 기반 | 역할 |
|----------|-----------|------|
| `backend-dev` | fastapi-specialist | API 엔드포인트 구현 |
| `sql-dev` | sql-query-specialist | SQL 쿼리 작성 |
| `frontend-dev` | react-specialist | React UI 구현 |
| `api-tester` | api-test-specialist | API 테스트 작성 |
| `reviewer` | code-quality-reviewer | 코드 품질/보안 리뷰 |

### Team 템플릿 복사 방법
```bash
# Team Lead 템플릿
cp templates/claude-teams/fullstack-team.md ../your-project/.claude/agents/

# Agent 템플릿 (필요한 것만 선택)
cp templates/claude-agents/fastapi-specialist.md ../your-project/.claude/agents/
cp templates/claude-agents/sql-query-specialist.md ../your-project/.claude/agents/
cp templates/claude-agents/react-specialist.md ../your-project/.claude/agents/
cp templates/claude-agents/api-test-specialist.md ../your-project/.claude/agents/
cp templates/claude-agents/code-quality-reviewer.md ../your-project/.claude/agents/
```

### 사용 예시
```bash
@fullstack-team 매출 목록 페이지 구현
```

자세한 내용은 `templates/workflows/fullstack-team-guide.md` 참조

## Code Generators

보일러플레이트 코드를 자동 생성하는 도구입니다.

| 생성기 | 지원 프레임워크 | 용도 |
|-------|--------------|------|
| `generate_api.py` | FastAPI, Express | CRUD API 엔드포인트 |
| `generate_component.py` | React, Vue | UI 컴포넌트 + 테스트 |
| `generate_test.py` | pytest, Jest | 단위 테스트 |

```bash
# 예시
python3 scripts/generators/generate_api.py users --type fastapi -o src/domains/user
python3 scripts/generators/generate_component.py UserList --type react --with-test -o src/components
python3 scripts/generators/generate_test.py user_service create_user --type pytest -o tests
```

자세한 내용은 `docs/code-generators-guide.md` 참조

## Claude Skills

메타 검증 스킬로 코드 품질을 자동 검증합니다.

| Skill | 역할 |
|-------|------|
| `dev-toolkit` | 코드 생성 도구 (API, 컴포넌트, 테스트 보일러플레이트) |
| `manage-skills` | 검증 스킬 자동 생성/업데이트 |
| `verify-implementation` | 모든 검증 스킬 통합 실행 |

프로젝트 적용: `./scripts/create-project.sh --name my-project --type fullstack --with-skills --with-generators`

자세한 내용은 `docs/claude-skills-guide.md` 참조

## 워크플로우

**리서치 → 계획 → PRD작성 → 구현 → 테스트**

자세한 내용은 `templates/workflows/development-workflow.md` 참조

## 기여 가이드

1. 변경사항은 PR로 제출
2. 팀 리뷰 후 병합
3. 모든 프로젝트에 영향을 미치므로 신중하게 결정
