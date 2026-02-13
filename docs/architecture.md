# Architecture

## 개요

`dev-standards`는 팀 개발 표준을 중앙에서 관리하고, 각 프로젝트에 일관된 설정과 워크플로우를 제공하는 저장소입니다.

---

## 디렉토리 구조

```
dev-standards/
├── packages/                    # 배포 가능한 설정 패키지
│   ├── eslint-config/           # @company/eslint-config (npm)
│   │   ├── index.js             # Base: TypeScript 규칙
│   │   ├── react.js             # React 확장 규칙
│   │   └── package.json
│   ├── prettier-config/         # @company/prettier-config (npm)
│   │   ├── index.json           # 포맷팅 설정
│   │   └── package.json
│   ├── typescript-config/       # @company/typescript-config (npm)
│   │   ├── base.json            # Base: Node.js/범용
│   │   ├── react.json           # React 확장
│   │   └── package.json
│   └── python-standards/        # company-python-standards (pip)
│       ├── src/                  # Ruff, mypy 설정
│       └── pyproject.toml
├── templates/                   # 복사하여 사용하는 템플릿
│   ├── claude-agents/           # Claude Code Agent 정의 파일
│   ├── claude-teams/            # Claude Code Team 정의 파일
│   ├── prd/                     # PRD(Product Requirements Document) 템플릿
│   ├── hooks/                   # Claude Code Hooks 스크립트
│   ├── backend/                 # Backend 공통 코드 템플릿
│   ├── frontend/                # Frontend 공통 코드 템플릿
│   ├── git/                     # Git 설정 템플릿
│   └── workflows/               # 워크플로우 문서
├── scripts/
│   └── create-project.sh        # 신규 프로젝트 생성 통합 스크립트
├── docs/                        # 프로젝트 문서
│   ├── architecture.md          # 아키텍처 문서 (이 파일)
│   ├── git-workflow.md          # Git 브랜치 전략
│   ├── commit-convention.md     # 커밋 메시지 컨벤션
│   ├── claude-hooks.md          # Claude Hooks 가이드
│   └── api-response-format.md   # API 응답 포맷 가이드
├── .github/                     # GitHub Actions 워크플로우
├── CLAUDE.md                    # Claude Code 지침
└── README.md                    # 프로젝트 소개
```

---

## 패키지 설계 원칙

### 1. 계층적 설정 상속

각 패키지는 Base 설정과 확장 설정으로 나뉘어, 프로젝트 유형에 맞게 선택할 수 있습니다.

```
@company/eslint-config
├── index.js    (Base: TypeScript)
└── react.js    (React 확장 = Base + React 규칙)

@company/typescript-config
├── base.json   (Base: Node.js/범용)
└── react.json  (React 확장 = Base + JSX/DOM)
```

### 2. Peer Dependencies 패턴

핵심 도구(`eslint`, `prettier`, `typescript`)는 `peerDependencies`로 선언하여, 프로젝트가 버전을 직접 관리합니다.

```json
{
  "peerDependencies": {
    "eslint": ">=9.0.0",
    "typescript": ">=5.0.0"
  }
}
```

### 3. ESLint Flat Config

ESLint 9+ Flat Config 형식을 사용합니다. 배열을 spread하여 확장이 용이합니다.

```javascript
// 프로젝트에서 커스터마이징
import config from '@company/eslint-config/react';
export default [
  ...config,
  { rules: { 'no-console': 'off' } },
];
```

### 4. 패키지 vs 템플릿 구분

| 구분 | 패키지 (`packages/`) | 템플릿 (`templates/`) |
|------|---------------------|----------------------|
| 배포 | npm/pip 레지스트리 | 파일 복사 |
| 업데이트 | `pnpm update` / `pip install --upgrade` | 수동 복사 |
| 용도 | 린트, 포맷팅, 타입 설정 | Agent, Team, PRD, 워크플로우 |
| 커스터마이징 | 설정 확장/오버라이드 | 복사 후 직접 수정 |

---

## 워크플로우

### 개발 흐름

```
리서치 → 계획 → PRD 작성 → 구현 → 테스트 → 코드 리뷰 → 배포
```

### 단계별 도구

| 단계 | 도구 | 설명 |
|------|------|------|
| 리서치 | Claude Code | 기존 코드 분석, 기술 조사 |
| 계획 | Plan Mode | 구현 계획 수립 |
| PRD 작성 | PRD 템플릿 | 화면/API 요구사항 문서화 |
| 구현 | Agent/Team | 전문 Agent 또는 Team 병렬 개발 |
| 테스트 | Vitest, Playwright, pytest | 단위/E2E/API 테스트 |
| 코드 리뷰 | code-quality-reviewer | 자동 코드 품질 리뷰 |

### Git 워크플로우

```
master (production)
   └── SKTL-XXXX (작업 브랜치)
         └── develop (테스트 환경)
```

- 브랜치는 JIRA 티켓 ID(`SKTL-XXXX`) 기반
- `develop`에 MR → 테스트 → `master`에 MR (GitLab에서만)
- 로컬에서 master push/merge 금지

---

## 기술 스택

### Frontend

| 카테고리 | 기술 | 버전 |
|----------|------|------|
| Framework | React | 18+ |
| Language | TypeScript | 5+ |
| Build | Vite | 5+ |
| State | Zustand | - |
| Grid | AG-Grid | - |
| Charts | Recharts | - |
| E2E Test | Playwright | - |
| Linting | ESLint (Flat Config) | 9+ |
| Formatting | Prettier | 3+ |

### Backend

| 카테고리 | 기술 | 버전 |
|----------|------|------|
| Framework | FastAPI | 0.111+ |
| Language | Python | 3.11+ |
| Database | PostgreSQL | 16+ |
| DB Driver | asyncpg | - |
| Validation | Pydantic | v2 |
| Linting | Ruff | 0.4+ |
| Type Check | mypy | 1.10+ |
| Test | pytest + httpx | - |
| Package Manager | uv | - |

### 아키텍처 패턴

**Backend 레이어 패턴:**
```
Router (요청 수신) → Service (비즈니스 로직) → Repository (SQL 실행)
```

- ORM 사용하지 않음 (순수 SQL + asyncpg)
- SQL 파일을 별도 디렉토리에 관리
- Service 레벨에서 트랜잭션 관리

**Frontend 도메인 패턴:**
```
src/domains/{domain}/
├── components/    # UI 컴포넌트
├── hooks/         # 커스텀 훅
├── stores/        # Zustand 스토어
├── pages/         # 페이지 컴포넌트
├── api/           # API 호출
└── types/         # 타입 정의
```

---

## Claude Code Agent 아키텍처

### Agent 구성

```
사용자 요청 → Agent 선택 → 코드 생성/수정 → 리뷰
```

| Agent | 레이어 | 전문 영역 |
|-------|--------|----------|
| react-specialist | Frontend | React, AG-Grid, Zustand |
| e2e-test-specialist | Frontend | Playwright E2E 테스트 |
| fastapi-specialist | Backend | FastAPI API 설계 |
| sql-query-specialist | Backend | PostgreSQL 쿼리 |
| api-test-specialist | Backend | pytest + httpx 테스트 |
| code-quality-reviewer | 공통 | 코드 품질, 보안 리뷰 |

### Team 구성 (Fullstack)

```
Phase 0: 분석 & 계획 ─── Team Lead
Phase 1: Backend + SQL ── sql-dev, backend-dev (병렬)
Phase 2: Frontend + Test ── frontend-dev, api-tester (병렬)
Phase 3: 코드 리뷰 ────── reviewer
Phase 4: 최종 확인 ────── Team Lead
```

---

## 신규 프로젝트 생성 흐름

```
create-project.sh 실행
    │
    ├── frontend 타입
    │   ├── React + Vite 프로젝트 초기화
    │   ├── ESLint, Prettier, TypeScript 설정
    │   ├── Docker, Nginx 설정
    │   ├── Claude Agent 템플릿 복사
    │   └── CLAUDE.md, README.md 생성
    │
    ├── backend 타입
    │   ├── FastAPI 프로젝트 초기화
    │   ├── Ruff, mypy 설정 (pyproject.toml)
    │   ├── Database 모듈, Docker 설정
    │   ├── Claude Agent 템플릿 복사
    │   └── CLAUDE.md, README.md 생성
    │
    └── fullstack 타입
        ├── Frontend + Backend 모두 생성
        ├── 루트 docker-compose.yml
        ├── 양쪽에 전체 Agent + Team 템플릿 복사
        └── Fullstack Team 가이드 포함
```

---

## 버전 관리 전략

- **Semantic Versioning** 사용
  - Major: 호환성이 깨지는 변경 (예: 규칙 삭제, 필수 설정 변경)
  - Minor: 새 규칙 추가 (예: 보안 규칙 추가)
  - Patch: 버그 수정 (예: 규칙 오류 수정)
- 각 패키지 독립적으로 버전 관리
- CHANGELOG.md로 변경 이력 추적
