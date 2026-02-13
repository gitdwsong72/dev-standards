# Contributing Guide

`dev-standards` 저장소에 기여하는 방법을 안내합니다.

---

## 시작하기

### 1. 저장소 클론

```bash
git clone <repository-url> dev-standards
cd dev-standards
```

### 2. 개발 환경 준비

```bash
# Node.js (패키지 테스트용)
node --version  # >= 18.0.0
pnpm --version  # >= 8.0.0

# Python (python-standards 패키지용)
python3 --version  # >= 3.11
uv --version
```

### 3. 브랜치 생성

```bash
git checkout master
git pull origin master
git checkout -b SKTL-XXXX  # JIRA 티켓 기반
```

---

## 패키지 수정

### ESLint 설정 수정 (`packages/eslint-config/`)

**규칙 추가/변경:**

```javascript
// packages/eslint-config/index.js
export default [
  // ...
  {
    rules: {
      // 새 규칙 추가
      'new-rule': 'error',
    },
  },
];
```

**테스트 방법:**

```bash
# 별도 테스트 프로젝트에서 로컬 패키지 연결
cd /path/to/test-project
pnpm add -D ../../dev-standards/packages/eslint-config

# ESLint 실행
pnpm eslint src/ --debug
```

**주의사항:**
- `error` 레벨 규칙 추가는 기존 프로젝트에 영향 → Minor 버전 업데이트
- `warn` → `error` 변경도 Major 버전으로 고려
- 보안 규칙은 `eslint-plugin-security` 활용

### Prettier 설정 수정 (`packages/prettier-config/`)

```json
// packages/prettier-config/index.json
{
  "semi": true,
  "singleQuote": true
  // 변경 또는 추가
}
```

**주의사항:**
- 포맷팅 변경은 모든 파일에 영향 → 팀 합의 필수
- 변경 후 `prettier --write "**/*.{ts,tsx}"` 실행 영향도 확인

### TypeScript 설정 수정 (`packages/typescript-config/`)

```json
// packages/typescript-config/base.json
{
  "compilerOptions": {
    // 새 옵션 추가
  }
}
```

**주의사항:**
- `strict` 관련 옵션 변경은 Major 버전
- 새 `compilerOptions` 추가는 Minor 버전
- `react.json`은 `base.json`을 상속하므로 base 변경 시 react도 확인

### Python 표준 수정 (`packages/python-standards/`)

```toml
# packages/python-standards/pyproject.toml 또는 ruff.toml
[tool.ruff.lint]
select = ["E", "W", "F", ...]  # 규칙 추가
```

---

## 템플릿 수정

### Agent 템플릿 (`templates/claude-agents/`)

Agent 템플릿은 Markdown 형식으로, Claude Code가 인식하는 에이전트 정의 파일입니다.

**수정 가이드:**
- 역할(`Role`), 전문 영역, 규칙을 명확하게 기술
- 코드 예시는 프로젝트 실제 패턴과 일치하도록 유지
- 새 Agent 추가 시 `CLAUDE.md`와 `README.md`의 Agent 목록도 업데이트

### PRD 템플릿 (`templates/prd/`)

- `endpoint.md`: API 엔드포인트 PRD
- `screen.md`: 화면 PRD
- `index.md`: PRD 목록 관리

**수정 가이드:**
- 섹션 추가/삭제 시 모든 PRD 형식의 일관성 유지
- 예시 코드와 테이블 구조를 실제 프로젝트에 맞게 유지

### 워크플로우 문서 (`templates/workflows/`)

- `development-workflow.md`: 전체 개발 흐름
- `fullstack-team-guide.md`: Team 사용 가이드
- `new-project-setup.md`: 프로젝트 생성 가이드

---

## 문서 작성

### docs/ 디렉토리

| 파일 | 용도 |
|------|------|
| `architecture.md` | 저장소 아키텍처 |
| `git-workflow.md` | Git 브랜치 전략 |
| `commit-convention.md` | 커밋 메시지 규칙 |
| `claude-hooks.md` | Claude Hooks 가이드 |
| `api-response-format.md` | API 응답 포맷 |
| `troubleshooting.md` | 문제 해결 가이드 |
| `contributing.md` | 기여 가이드 (이 파일) |

**작성 규칙:**
- 한국어로 작성 (코드와 기술 용어는 영문 유지)
- 코드 예시는 실행 가능한 형태로 작성
- 모든 문서에 목차(Heading) 구조 유지

---

## 테스트

### 패키지 테스트

각 패키지를 수정한 후, 실제 프로젝트에서 정상 동작하는지 확인합니다.

```bash
# 1. 테스트용 프로젝트 생성
./scripts/create-project.sh -n test-project -t fullstack

# 2. 로컬 패키지 링크 (npm)
cd test-project/test-project-frontend
pnpm add -D ../../packages/eslint-config
pnpm add -D ../../packages/prettier-config
pnpm add -D ../../packages/typescript-config

# 3. 린트/포맷팅/타입체크 실행
pnpm eslint src/
pnpm prettier --check "src/**/*.{ts,tsx}"
pnpm tsc --noEmit
```

### create-project.sh 테스트

```bash
# 각 타입별 테스트
./scripts/create-project.sh -n test-fe -t frontend -d /tmp
./scripts/create-project.sh -n test-be -t backend -d /tmp
./scripts/create-project.sh -n test-fs -t fullstack -d /tmp

# 생성된 프로젝트 확인
ls -la /tmp/test-fe/
ls -la /tmp/test-be/
ls -la /tmp/test-fs/
```

### 문서 확인

- Markdown 렌더링 확인 (GitLab/GitHub Preview)
- 링크 깨짐 확인
- 코드 블록 문법 확인

---

## 배포

### npm 패키지 배포

```bash
# 1. 버전 업데이트
cd packages/eslint-config
# package.json의 version 필드 수정

# 2. CHANGELOG.md 작성
# 변경 내용을 CHANGELOG.md에 기록

# 3. 커밋 & 태그
git add .
git commit -m "chore(eslint-config): bump version to 1.1.0"
git tag @company/eslint-config@1.1.0

# 4. 배포
npm publish --access public
# 또는 사내 레지스트리
npm publish --registry https://your-registry.com
```

### pip 패키지 배포

```bash
# 1. 버전 업데이트
cd packages/python-standards
# pyproject.toml의 version 필드 수정

# 2. 빌드 & 배포
uv build
uv publish
# 또는 사내 레지스트리
uv publish --index-url https://your-registry.com
```

---

## Code Review 가이드

### 리뷰 체크리스트

**패키지 수정 시:**
- [ ] 기존 프로젝트와 호환성 유지 (breaking change 확인)
- [ ] Semantic Versioning 올바르게 적용
- [ ] CHANGELOG.md 업데이트
- [ ] package.json / pyproject.toml 버전 업데이트
- [ ] 테스트 프로젝트에서 동작 확인

**템플릿 수정 시:**
- [ ] 기존 Agent/PRD와 일관성 유지
- [ ] 코드 예시가 최신 패턴 반영
- [ ] create-project.sh에 반영 필요 여부 확인

**문서 수정 시:**
- [ ] 한국어 작성 (기술 용어 영문)
- [ ] 코드 예시 실행 가능
- [ ] 링크 정상 동작
- [ ] CLAUDE.md, README.md 관련 항목 동기화

### 리뷰 프로세스

1. MR(Merge Request) 생성
2. 최소 1명 이상의 팀원 리뷰
3. CI 통과 확인
4. 리뷰 승인 후 병합

### 영향도 분류

| 변경 유형 | 영향도 | 리뷰어 수 |
|-----------|--------|----------|
| 패키지 규칙 변경 (Major) | 전체 프로젝트 | 2명 이상 |
| 패키지 규칙 추가 (Minor) | 전체 프로젝트 | 1명 이상 |
| 템플릿 수정 | 신규 프로젝트 | 1명 이상 |
| 문서 수정 | 낮음 | 1명 이상 |
| 스크립트 수정 | 신규 프로젝트 | 1명 이상 |

---

## 커밋 메시지 예시

```bash
# 패키지 수정
feat(eslint-config): add import sorting rule
fix(prettier-config): correct trailingComma setting
chore(typescript-config): bump version to 1.1.0

# 템플릿 수정
feat(agents): add sql-query-specialist template
fix(prd): correct endpoint template schema section

# 문서 수정
docs(readme): update quick start guide
docs(workflow): add fullstack team guide

# 스크립트 수정
feat(scripts): add fullstack project type to create-project
fix(scripts): resolve path validation issue
```
