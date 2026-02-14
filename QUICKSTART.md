# dev-standards Quick Start (5분 완주)

새 프로젝트를 5분 안에 생성하고 첫 기능을 구현해보세요.

## 🚀 신규 프로젝트 생성 (2분)

### 1단계: 프로젝트 스캐폴딩 (30초)

```bash
cd /path/to/your/workspace
git clone <repository-url> dev-standards
cd dev-standards
./scripts/create-project.sh --name my-app --type fullstack --with-skills --with-generators
```

**옵션 설명:**
- `--type fullstack`: Frontend(React) + Backend(FastAPI) 생성
- `--with-skills`: 검증 스킬 3개 자동 복사 (`/manage-skills`, `/verify-implementation`, `/dev-toolkit`)
- `--with-generators`: 코드 생성기 3개 복사 (API, Component, Test 생성 도구)

### 2단계: 디렉토리 이동 및 확인 (30초)

```bash
cd ../my-app
tree -L 2 -a  # 구조 확인
```

**생성된 주요 파일:**
```
my-app/
├── frontend/          # React 18 + TypeScript
├── backend/           # FastAPI + PostgreSQL
├── .claude/           # Agent 6개, Skills 3개, Hooks
│   ├── agents/        # fastapi-specialist, react-specialist 등
│   ├── skills/        # dev-toolkit, manage-skills, verify-implementation
│   ├── CLAUDE.md      # Agent 사용 가이드
│   └── hooks/         # user-prompt-submit (PRD 링크 자동 읽기)
└── docs/              # 개발 워크플로우, 참조 문서
```

### 3단계: 개발 환경 설정 (1분)

```bash
# Frontend (Node 20+ 필요)
cd frontend && pnpm install && cd ..

# Backend (Python 3.11+ 필요)
cd backend && uv pip install -r requirements.txt && cd ..
```

---

## ⚡ 첫 기능 구현 (3분)

### Scenario: "사용자 목록 API + UI" 구현

#### 1단계: PRD 작성 (1분)

```bash
cat > feature-user-list.md <<'EOF'
# 기능: 사용자 목록 조회

## 요구사항
- GET /api/v1/users 엔드포인트
- 페이지네이션 지원 (skip, limit)
- 사용자 이름으로 검색 (query parameter: search)
- React 컴포넌트로 목록 표시

## 응답 형식
{
  "items": [
    {"id": 1, "name": "John Doe", "email": "john@example.com"}
  ],
  "total": 100
}
EOF
```

#### 2단계: Agent에게 구현 위임 (1분)

```bash
# Claude Code CLI 실행
claude

# 프롬프트 입력:
@fullstack-team feature-user-list.md 기반으로 API + Frontend 구현
```

**자동 처리 내용:**
1. Hook이 PRD 파일 자동 읽기
2. Team Lead가 5명의 전문가에게 작업 배분:
   - `backend-dev`: FastAPI 라우터 생성
   - `sql-dev`: User 모델/쿼리 작성
   - `frontend-dev`: UserList 컴포넌트 생성
   - `api-tester`: API 테스트 작성
   - `reviewer`: 코드 품질/보안 리뷰
3. 병렬 작업 후 통합

#### 3단계: 검증 스킬 실행 (30초)

```bash
/verify-implementation
```

**검증 항목:**
- ✅ 코드 품질 (ESLint, Ruff)
- ✅ 타입 체크 (TypeScript, mypy)
- ✅ 보안 (ESLint security, Ruff bandit)
- ✅ 테스트 커버리지
- ✅ 문서화 (docstring, JSDoc)

**예상 결과:**
```
✅ Backend: backend/src/routers/users_router.py 생성
✅ Backend Test: backend/tests/test_users_router.py 생성
✅ Frontend: frontend/src/components/UserList/UserList.tsx 생성
✅ Frontend Test: frontend/src/components/UserList/UserList.test.tsx 생성
✅ 검증 통과: 모든 품질 기준 충족
```

---

## 📚 다음 단계

### 코드 생성기 직접 사용

개별 파일을 빠르게 생성할 때 사용:

```bash
# API 엔드포인트 생성 (CRUD 보일러플레이트)
python3 dev-standards/scripts/generators/generate_api.py posts \
  --type fastapi -o backend/src/routers

# React 컴포넌트 생성 (TypeScript + 테스트)
python3 dev-standards/scripts/generators/generate_component.py PostCard \
  --type react --with-test -o frontend/src/components

# 테스트 파일 생성 (pytest boilerplate)
python3 dev-standards/scripts/generators/generate_test.py post_service \
  create_post update_post --type pytest -o backend/tests
```

### Agent 직접 호출

복잡한 작업을 전문가 Agent에게 위임:

```bash
@fastapi-specialist 결제 API 구현 (Stripe 연동)
@react-specialist 대시보드 차트 구현 (Recharts)
@sql-query-specialist 복잡한 집계 쿼리 최적화
@code-quality-reviewer 보안 취약점 전수 검사
```

### Skills 활용

```bash
/dev-toolkit                # 코드 생성 대화형 도구
/manage-skills              # 새 검증 스킬 추가
/verify-implementation      # 통합 검증 실행
```

### 상세 가이드

| 주제 | 문서 |
|------|------|
| 📖 전체 워크플로우 | [templates/workflows/development-workflow.md](templates/workflows/development-workflow.md) |
| 🤖 Agent 가이드 | [.claude/CLAUDE.md](.claude/CLAUDE.md) |
| ⚙️ 코드 생성기 | [docs/code-generators-guide.md](docs/code-generators-guide.md) |
| 🔍 Skills 가이드 | [docs/claude-skills-guide.md](docs/claude-skills-guide.md) |
| 👥 Fullstack Team | [templates/workflows/fullstack-team-guide.md](templates/workflows/fullstack-team-guide.md) |

---

## ⚠️ 자주 묻는 질문 (FAQ)

### Q1: "검증 스킬 0개" 에러가 나옵니다

**원인**: 첫 사용 시 검증 스킬이 아직 생성되지 않은 상태입니다.

**해결법** (정상 워크플로우):
1. 기능 구현 먼저 완료 (Agent 또는 직접 코딩)
2. `/manage-skills` 실행 → 코드 분석 후 새 스킬 자동 생성
3. `/verify-implementation` 실행 → 생성된 스킬로 검증

**예시:**
```bash
# 1. 기능 구현
@fastapi-specialist 사용자 등록 API 구현

# 2. 검증 스킬 생성 (처음 한 번만)
/manage-skills
> "사용자 등록 API" 관련 스킬 자동 생성됨

# 3. 검증 실행
/verify-implementation
> ✅ 검증 완료
```

### Q2: PRD를 Agent에게 어떻게 전달하나요?

**방법 1**: 파일 경로 제공 (Hook 자동 읽기)
```bash
@fastapi-specialist feature-user-list.md 기반으로 구현
# → Hook이 파일 내용 자동 로드
```

**방법 2**: 내용 직접 붙여넣기
```bash
@fastapi-specialist 다음 PRD 기반으로 구현:

# 기능: 사용자 등록
## 요구사항
- POST /api/v1/users
- 이메일 중복 검사
[...]
```

**방법 3**: `/read` 명령어 사용
```bash
/read feature-user-list.md
@fastapi-specialist 위 PRD 기반으로 구현
```

### Q3: Fullstack Team이 타임아웃되거나 비용이 걱정됩니다

**원인**: 5명의 Agent가 동시 작업 시 API 사용량 증가

**해결법 1**: 작업 분할
```bash
# 단계별 진행
@backend-dev API 먼저 구현
@frontend-dev API 완료 후 UI 구현
@reviewer 전체 리뷰
```

**해결법 2**: 개별 Agent 순차 호출
```bash
# 1단계: Backend
@fastapi-specialist API 엔드포인트 구현
@api-test-specialist 테스트 작성

# 2단계: Frontend
@react-specialist UI 컴포넌트 구현

# 3단계: 검증
@code-quality-reviewer 전체 리뷰
```

**해결법 3**: 코드 생성기 먼저 사용
```bash
# 보일러플레이트는 생성기로 생성
python3 dev-standards/scripts/generators/generate_api.py users --type fastapi
python3 dev-standards/scripts/generators/generate_component.py UserList --type react

# Agent는 비즈니스 로직만 추가
@fastapi-specialist users API에 이메일 중복 검사 로직 추가
```

### Q4: `--with-skills` 없이 프로젝트를 생성했습니다

**해결법**: 수동 복사
```bash
# Skills 복사
cp -r dev-standards/templates/claude-skills/* my-app/.claude/skills/

# Hooks 복사 (PRD 자동 읽기)
cp -r dev-standards/templates/hooks/* my-app/.claude/hooks/
```

### Q5: Node/Python 버전 요구사항은?

**필수 버전:**
- Node.js: **20.x 이상** (ESM, native fetch 사용)
- Python: **3.11 이상** (Pydantic v2, native TOML 파싱)
- pnpm: **9.x 이상**
- uv: **0.5.x 이상**

**확인 명령어:**
```bash
node --version    # v20.0.0 이상
python --version  # 3.11.0 이상
pnpm --version    # 9.0.0 이상
uv --version      # 0.5.0 이상
```

### Q6: ESLint 9로 마이그레이션 시 주의사항은?

**주요 변경사항:**
- Flat Config 필수 (`.eslintrc.*` → `eslint.config.js`)
- 일부 플러그인 미지원 (호환 버전 확인 필요)

**마이그레이션 가이드**: (작성 예정)
- `docs/migration/eslint-8-to-9.md` 참조 예정

---

## 🎯 학습 경로

### 초급 (1-3일)
1. ✅ Quick Start 완주 (이 문서)
2. 📖 [Development Workflow](templates/workflows/development-workflow.md) 읽기
3. 🤖 개별 Agent 사용 (@fastapi-specialist, @react-specialist)
4. ⚙️ 코드 생성기 사용 (generate_api.py, generate_component.py)

### 중급 (1-2주)
1. 👥 Fullstack Team 활용
2. 🔍 커스텀 검증 스킬 작성 (`/manage-skills`)
3. 📝 PRD 템플릿 커스터마이징
4. 🔧 Hook 커스터마이징 (pre-commit, user-prompt-submit)

### 고급 (1개월+)
1. 🧩 새 Agent 템플릿 작성 (도메인 전문가)
2. 📦 새 코드 생성기 개발 (템플릿 기반)
3. 🏗️ Monorepo 적용
4. 🌐 팀 표준 기여 (패키지 버전 업데이트)

---

## 💡 팁

### 효율적인 Agent 활용
- ✅ **DO**: 명확한 요구사항 제공 (PRD, 예시 코드)
- ✅ **DO**: 복잡한 작업은 단계별 분할
- ❌ **DON'T**: 모호한 지시 ("좋은 코드 작성해줘")
- ❌ **DON'T**: 너무 많은 작업 한 번에 요청

### 코드 생성기 vs Agent 선택
- **코드 생성기**: 표준 보일러플레이트 (CRUD API, UI 컴포넌트 뼈대)
- **Agent**: 비즈니스 로직, 복잡한 알고리즘, 통합 작업

### 검증 스킬 활용
- 구현 완료 후 항상 `/verify-implementation` 실행
- 실패 항목은 자동 리포트 생성 → 수정 가이드 제공
- 커스텀 검증 규칙은 `/manage-skills`로 추가

---

## 🆘 도움말

| 문제 유형 | 해결 방법 |
|----------|----------|
| 🐛 버그 리포트 | [GitHub Issues](https://github.com/your-org/dev-standards/issues) |
| 💬 질문 | 팀 Slack #dev-standards 채널 |
| 📖 문서 업데이트 | PR 제출 (CONTRIBUTING.md 참조) |
| 🔧 설정 문제 | [Troubleshooting](docs/troubleshooting.md) |

---

**축하합니다! 🎉** 이제 dev-standards를 활용한 개발 준비가 완료되었습니다.
다음 단계는 [Development Workflow](templates/workflows/development-workflow.md)를 읽고 실제 프로젝트에 적용해보세요.
