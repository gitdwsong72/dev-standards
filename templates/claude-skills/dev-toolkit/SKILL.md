---
name: dev-toolkit
description: "Python 및 TypeScript/JavaScript 프로젝트를 위한 범용 개발 도구입니다. React/Vue 컴포넌트나 FastAPI/Express API 엔드포인트 보일러플레이트 코드 생성, pytest/Jest 테스트 파일 생성, Git 워크플로우 모범 사례, Python/TypeScript 코딩 패턴 적용이 필요할 때 이 스킬을 사용합니다. 심화 작업이 필요한 경우 전문 스킬(react-specialist, fastapi-specialist, api-test-specialist 등)을 참조하세요."
---

# 개발 도구 (Dev Toolkit)

보일러플레이트 코드, 테스트 생성, 모범 사례, 모던 개발 도구 참조를 위한 범용 개발 도구입니다.

## 역할 및 범위

dev-toolkit은 **프로젝트 초기 설정과 범용 코드 생성**에 집중합니다:
- 프로젝트 스캐폴딩 및 보일러플레이트 생성
- 기본 CRUD API 라우터 / 컴포넌트 / 테스트 파일 생성
- Git 워크플로우, 코딩 패턴, 모던 도구 참조 제공
- CI/CD 파이프라인, 린팅/포맷팅 설정 가이드

**심화 작업은 전문 스킬에 위임하세요:**

| 작업 | 전문 스킬 |
|------|-----------|
| React 고급 패턴 (AG-Grid, Recharts, Zustand) | `react-specialist` |
| FastAPI 설계 (Pydantic v2, DI, 인증/인가) | `fastapi-specialist` |
| API 테스트 (httpx, 통합 테스트) | `api-test-specialist` |
| E2E 테스트 (Playwright, POM) | `e2e-test-specialist` |
| SQL 쿼리 최적화 | `sql-query-specialist` |
| 코드 품질/보안 리뷰 | `code-quality-reviewer` |

## 코드 생성

### React/Vue 컴포넌트 생성

```bash
# React 컴포넌트 (테스트 포함)
python3 scripts/generators/generate_component.py ComponentName --type react --with-test -o src/components

# Vue 컴포넌트 (테스트 포함)
python3 scripts/generators/generate_component.py ComponentName --type vue --with-test -o src/components

# 미리보기 (파일 생성 없이)
python3 scripts/generators/generate_component.py ComponentName --type react --dry-run

# 기존 파일 덮어쓰기
python3 scripts/generators/generate_component.py ComponentName --type react --force
```

**생성되는 파일:**
- React: `ComponentName.tsx`, `ComponentName.test.tsx`, `index.ts`
- Vue: `ComponentName.vue`, `ComponentName.test.ts` (vitest)

### API 엔드포인트 생성

```bash
# FastAPI 라우터 (Python)
python3 scripts/generators/generate_api.py users --type fastapi -o src/routers

# Express 라우터 (TypeScript)
python3 scripts/generators/generate_api.py users --type express -o src/routes

# 미리보기
python3 scripts/generators/generate_api.py users --type fastapi --dry-run
```

**생성되는 기능:**
- CRUD 엔드포인트 (GET, POST, PUT, DELETE)
- 페이지네이션 (skip, limit)
- Update 스키마 (부분 업데이트 지원)
- ID 파라미터 검증
- 타임스탬프 (createdAt, updatedAt)

### 테스트 생성

```bash
# pytest 테스트
python3 scripts/generators/generate_test.py user_service create_user get_user --type pytest -o tests

# Jest 테스트
python3 scripts/generators/generate_test.py userService createUser getUser --type jest -o __tests__

# 미리보기
python3 scripts/generators/generate_test.py user_service create_user --type pytest --dry-run
```

**테스트 구조:**
- AAA 패턴 (Arrange-Act-Assert)
- 함수별 success + edge case 테스트 케이스
- 공유 테스트 데이터 (sample_data fixture / mockData)

## 프로젝트 스캐폴딩 워크플로우

새 프로젝트 시작 시 권장 순서:

1. **프로젝트 구조 생성** — [docs/references/modern-tooling.md](docs/references/modern-tooling.md)의 권장 구조 참고
2. **API 라우터 생성** — `generate_api.py`로 CRUD 보일러플레이트 생성
3. **컴포넌트 생성** — `generate_component.py`로 UI 컴포넌트 생성
4. **테스트 생성** — `generate_test.py`로 테스트 스켈레톤 생성
5. **CI/CD 설정** — [docs/references/git-workflows.md](docs/references/git-workflows.md)의 GitHub Actions 예시 활용
6. **린팅/포맷팅** — [docs/references/modern-tooling.md](docs/references/modern-tooling.md)의 ESLint/Ruff/Biome 설정 참고

## Git 워크플로우

브랜치 명명 규칙, 커밋 메시지 형식, PR 템플릿, 시맨틱 버전 관리, CI/CD 파이프라인은 [docs/references/git-workflows.md](docs/references/git-workflows.md) 참조.

주요 규칙:
- 브랜치: `feature/<티켓>-<설명>`, `bugfix/<티켓>-<설명>`
- 커밋: `<타입>(<범위>): <제목>` (Conventional Commits)
- 타입: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

## 코딩 패턴

Python (FastAPI, Pydantic v2, pytest) 및 TypeScript (React, TanStack Query, Zod, Express) 패턴은 [docs/references/coding-patterns.md](docs/references/coding-patterns.md) 참조.

## 모던 개발 도구

패키지 매니저 (pnpm, uv), 빌드 도구 (Vite, tsup), 린팅/포맷팅 (ESLint flat config, Ruff, Biome), 프로젝트 구조, Docker 멀티스테이지 빌드는 [docs/references/modern-tooling.md](docs/references/modern-tooling.md) 참조.

## 템플릿 커스터마이징

템플릿 파일들은 `templates/code-generators/` 디렉토리에서 수정 가능:
- `fastapi_router.py.template` - FastAPI 라우터 (Pydantic v2, status 상수)
- `express_router.ts.template` - Express 라우터 (타임스탬프 포함)
- `react_component.tsx.template` - React 컴포넌트 (함수 선언, children 지원)
- `vue_component.vue.template` - Vue 컴포넌트 (slot, defineEmits 포함)
- `pytest_test.py.template` - pytest 테스트 (sample_data fixture)
- `jest_test.ts.template` - Jest 테스트 (mockData 포함)

## 작업 흐름

1. **새 기능**: 브랜치 생성 → 보일러플레이트 생성 → 구현 → 테스트 작성
2. **버그 수정**: bugfix 브랜치 생성 → 실패하는 테스트 작성 → 수정 → 검증
3. **리팩토링**: 테스트 통과 확인 → 리팩토링 → 테스트 재확인

## 에러 처리

모든 스크립트는 다음 에러 상황을 처리합니다:
- 잘못된 입력값 (빈 이름, 잘못된 문자)
- 템플릿 파일 누락
- 기존 파일 충돌 (`--force`로 덮어쓰기)
- 권한 거부
- 예기치 않은 오류

## 공통 플래그

모든 생성 스크립트에서 사용 가능:
- `--dry-run` — 파일을 생성하지 않고 미리보기
- `--force` — 기존 파일 덮어쓰기
- `--output`, `-o` — 출력 디렉토리 지정
- `--help`, `-h` — 사용법 확인
