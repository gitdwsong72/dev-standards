# Commit Convention

## 형식

```
<type>(<scope>): <subject>

<body>

<footer>
```

---

## Type

| Type | 설명 | 예시 |
|------|------|------|
| `feat` | 새로운 기능 추가 | feat(user): add login page |
| `fix` | 버그 수정 | fix(cart): resolve quantity update issue |
| `docs` | 문서 수정 | docs(readme): update installation guide |
| `style` | 코드 포맷팅 (기능 변경 없음) | style(button): fix indentation |
| `refactor` | 리팩토링 | refactor(api): extract common fetch logic |
| `perf` | 성능 개선 | perf(list): implement virtual scrolling |
| `test` | 테스트 추가/수정 | test(user): add login unit tests |
| `chore` | 빌드, 설정 변경 | chore(deps): update eslint to v9 |
| `ci` | CI 설정 변경 | ci(github): add lint workflow |
| `revert` | 커밋 되돌리기 | revert: feat(user): add login page |

---

## Scope

도메인 또는 모듈 이름을 사용합니다.

### Frontend
- `user`, `order`, `product` (도메인)
- `grid`, `chart`, `modal` (컴포넌트)
- `auth`, `api` (기능)

### Backend
- `user`, `order`, `product` (도메인)
- `db`, `auth`, `cache` (인프라)

---

## Subject

- 50자 이내
- 소문자로 시작
- 마침표 없음
- 명령형 사용 (add, fix, update, remove)

### Good Examples
```
feat(user): add email verification flow
fix(order): resolve payment calculation error
refactor(api): simplify error handling logic
```

### Bad Examples
```
feat(user): Added email verification  # 과거형 사용
Fix: bug in order module  # scope 누락, 대문자
feat(user): add email verification flow.  # 마침표
```

---

## Body (선택)

- 72자마다 줄바꿈
- **무엇**을, **왜** 변경했는지 설명
- 어떻게(how)보다 무엇을/왜(what/why) 중심

```
feat(order): add bulk order processing

기존에는 주문을 하나씩만 처리할 수 있었으나,
대량 주문 처리 요구사항이 있어 일괄 처리 기능을 추가함.

- 최대 100건까지 동시 처리 가능
- 트랜잭션 단위로 롤백 지원
```

---

## Footer (선택)

### Breaking Changes
```
BREAKING CHANGE: remove deprecated getUserById API

Migration: getUserById(id) → getUser({ id })
```

### Issue Reference
```
Closes #123
Fixes #456
Refs #789
```

---

## 전체 예시

```
feat(cart): add product quantity validation

사용자가 재고 이상의 수량을 입력하는 것을 방지하기 위해
장바구니에 수량 검증 로직을 추가함.

- 최대 수량을 재고량으로 제한
- 초과 시 에러 메시지 표시
- 실시간 재고 확인 API 연동

Closes #234
```

---

## 자주 사용하는 동사

| 동사 | 사용 상황 |
|------|----------|
| add | 새로운 기능/파일 추가 |
| remove | 기능/파일 삭제 |
| update | 기존 기능 수정/개선 |
| fix | 버그 수정 |
| refactor | 코드 구조 개선 |
| rename | 이름 변경 |
| move | 파일/코드 이동 |
| extract | 코드 분리/추출 |
| simplify | 코드 단순화 |
| optimize | 성능 최적화 |

---

## Commitlint 자동 검증

커밋 메시지는 commitlint를 통해 자동으로 검증됩니다. `create-project.sh`로 생성한 프로젝트에는 이미 설정이 포함되어 있습니다.

### Frontend 프로젝트 (pnpm + husky)

```bash
# 의존성 설치 시 husky가 자동 초기화됩니다
pnpm install

# 이후 모든 커밋에서 자동 검증
git commit -m "feat(user): add login page"  # ✓ 통과
git commit -m "Add login page"              # ✗ 실패
```

**자동 설정 내용:**
- `@commitlint/cli`, `@commitlint/config-conventional`, `husky` devDependencies 포함
- `commitlint.config.js` 설정 파일 포함
- `.husky/commit-msg` hook 설정 완료
- `pnpm install` 시 `prepare` 스크립트로 husky 자동 초기화

### Backend 프로젝트 (Python + git hooks)

```bash
# 최초 1회 실행
./scripts/setup-commitlint.sh

# 이후 모든 커밋에서 자동 검증
git commit -m "feat(user): add login endpoint"  # ✓ 통과
git commit -m "fixed bug"                       # ✗ 실패
```

**자동 설정 내용:**
- `commitlint.config.js` 설정 파일 포함
- `.githooks/commit-msg` hook 설정 완료
- `scripts/setup-commitlint.sh` 실행으로 git hooks 경로 연결

### 수동 설정 (기존 프로젝트)

기존 프로젝트에 commitlint를 추가하려면:

```bash
# 1. 템플릿 복사
cp dev-standards/templates/git/commitlint.config.js ./

# 2-a. Frontend (pnpm + husky)
pnpm add -D @commitlint/cli @commitlint/config-conventional husky
npx husky init
cp dev-standards/templates/git/commit-msg-hook.sh .husky/commit-msg
chmod +x .husky/commit-msg

# 2-b. Backend (git hooks 직접 설정)
mkdir -p .githooks
cp dev-standards/templates/git/commit-msg-hook.sh .githooks/commit-msg
chmod +x .githooks/commit-msg
git config core.hooksPath .githooks
```

### 검증 규칙

| 규칙 | 수준 | 설명 |
|------|------|------|
| `type-enum` | error | 허용된 type만 사용 가능 |
| `type-case` | error | type은 소문자 |
| `type-empty` | error | type은 필수 |
| `scope-case` | error | scope은 소문자 |
| `subject-case` | error | subject는 소문자로 시작 |
| `subject-empty` | error | subject는 필수 |
| `subject-max-length` | error | subject 50자 이내 |
| `subject-full-stop` | error | subject 끝에 마침표 금지 |
| `header-max-length` | error | header 전체 72자 이내 |
| `body-max-line-length` | error | body 줄당 72자 이내 |

### 검증 실패 시 에러 메시지 예시

```
⧗   input: Add new feature
✖   subject may not be empty [subject-empty]
✖   type may not be empty [type-empty]

✖   found 2 problems, 0 warnings

ⓘ   올바른 형식: type(scope): subject
ⓘ   예시: feat(user): add login page
```

### 설정 파일

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
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [2, 'always', 'lower-case'],
    'subject-max-length': [2, 'always', 50],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 72],
  },
};
```
