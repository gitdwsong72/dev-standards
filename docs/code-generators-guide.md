# Code Generators 사용 가이드

## 개요

dev-standards에 통합된 코드 생성 도구입니다. [dev-toolkit-skill](https://github.com/your-org/dev-toolkit-skill)에서 가져온 Python 스크립트로, API 엔드포인트/UI 컴포넌트/테스트 파일의 보일러플레이트 코드를 자동 생성합니다.

## 지원 프레임워크

| 생성기 | Python | TypeScript |
|-------|--------|-----------|
| API 엔드포인트 | FastAPI (Pydantic v2) | Express |
| UI 컴포넌트 | - | React, Vue |
| 테스트 | pytest | Jest |

## 사용법

### API 엔드포인트 생성

```bash
# FastAPI CRUD 라우터
python3 scripts/generators/generate_api.py users --type fastapi -o src/routers

# Express CRUD 라우터
python3 scripts/generators/generate_api.py users --type express -o src/routes

# 미리보기 (파일 생성 없이)
python3 scripts/generators/generate_api.py users --type fastapi --dry-run
```

생성되는 기능:
- CRUD 엔드포인트 (GET list, GET single, POST, PUT, DELETE)
- 페이지네이션 (skip, limit 파라미터)
- 부분 업데이트 지원 (Update 스키마)
- ID 파라미터 검증
- 타임스탬프 (createdAt, updatedAt)

### UI 컴포넌트 생성

```bash
# React 컴포넌트 + 테스트 + index.ts
python3 scripts/generators/generate_component.py UserProfile --type react --with-test -o src/components

# Vue 컴포넌트 + 테스트
python3 scripts/generators/generate_component.py UserProfile --type vue --with-test -o src/components

# 미리보기
python3 scripts/generators/generate_component.py UserProfile --type react --dry-run
```

생성되는 파일:
- React: `ComponentName/ComponentName.tsx`, `ComponentName.test.tsx`, `index.ts`
- Vue: `ComponentName.vue`, `ComponentName.test.ts`

### 테스트 생성

```bash
# pytest 테스트
python3 scripts/generators/generate_test.py user_service create_user get_user --type pytest -o tests

# Jest 테스트
python3 scripts/generators/generate_test.py userService createUser getUser --type jest -o __tests__

# 미리보기
python3 scripts/generators/generate_test.py user_service create_user --type pytest --dry-run
```

테스트 구조:
- AAA 패턴 (Arrange-Act-Assert)
- 함수별 success + edge case 테스트 케이스
- 공유 테스트 데이터 (pytest: `sample_data` fixture / Jest: `mockData`)

## 공통 플래그

모든 생성 스크립트에서 사용 가능:

| 플래그 | 설명 |
|-------|------|
| `--dry-run` | 파일을 생성하지 않고 미리보기 |
| `--force` | 기존 파일 덮어쓰기 |
| `--output`, `-o` | 출력 디렉토리 지정 |
| `--help`, `-h` | 사용법 확인 |

## 템플릿 커스터마이징

템플릿 파일은 `templates/code-generators/` 디렉토리에 위치합니다:

| 템플릿 | 설명 |
|-------|------|
| `fastapi_router.py.template` | FastAPI 라우터 (Pydantic v2, status 상수, DI) |
| `express_router.ts.template` | Express 라우터 (타임스탬프, ID 검증) |
| `react_component.tsx.template` | React 함수형 컴포넌트 (children 지원) |
| `react_component.test.tsx.template` | React Testing Library 테스트 |
| `react_index.ts.template` | 배럴 익스포트 |
| `vue_component.vue.template` | Vue Composition API (slot, defineEmits) |
| `vue_component.test.ts.template` | Vitest 테스트 |
| `pytest_test.py.template` | pytest 클래스 기반 테스트 (fixture) |
| `pytest_method.py.template` | pytest 메서드 (AAA 패턴) |
| `jest_test.ts.template` | Jest describe 블록 |
| `jest_case.ts.template` | Jest 테스트 케이스 (AAA 패턴) |

템플릿은 Python `str.format()` 구문을 사용합니다. 변수:
- `{name}` / `{name_lower}` - 컴포넌트 이름
- `{resource}` / `{resource_singular}` / `{model}` - API 리소스 이름
- `{module}` / `{functions}` / `{class_name}` - 테스트 모듈 이름

## 참조 문서

코드 생성기와 함께 활용할 수 있는 기술 참조 문서:

- [docs/references/coding-patterns.md](references/coding-patterns.md) - Python/TypeScript 실전 패턴 (Pydantic v2, TanStack Query, Error Boundary 등)
- [docs/references/git-workflows.md](references/git-workflows.md) - 브랜치/커밋/PR/CI/CD 범용 가이드
- [docs/references/modern-tooling.md](references/modern-tooling.md) - pnpm, uv, Vite, Ruff, Biome, Docker 설정
