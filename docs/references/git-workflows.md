# Git 워크플로우 참조

## 브랜치 명명 규칙

```
feature/<티켓-ID>-<간단한-설명>
bugfix/<티켓-ID>-<간단한-설명>
hotfix/<티켓-ID>-<간단한-설명>
refactor/<간단한-설명>
docs/<간단한-설명>
```

## 커밋 메시지 형식

Conventional Commits 규칙을 따릅니다:

```
<타입>(<범위>): <제목>

[선택적 본문]

[선택적 푸터]
```

### 타입
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 변경만
- `style`: 코드 스타일 (포맷팅, 세미콜론 등)
- `refactor`: 기능 추가/버그 수정이 아닌 코드 변경
- `perf`: 성능 개선
- `test`: 테스트 추가 또는 수정
- `chore`: 빌드 프로세스, 도구, 의존성

### 예시
```
feat(auth): OAuth2 로그인 지원 추가
fix(api): 외부 서비스의 null 응답 처리
docs(readme): 설치 방법 업데이트
refactor(utils): 날짜 포맷팅 로직 단순화
```

## 자주 사용하는 Git 명령어

### 기능 개발
```bash
# 새 기능 브랜치 시작
git checkout -b feature/ABC-123-user-profile

# 특정 파일 스테이징
git add src/components/UserProfile.tsx

# 메시지와 함께 커밋
git commit -m "feat(user): 프로필 컴포넌트 추가"

# 푸시 및 PR 생성
git push -u origin feature/ABC-123-user-profile
```

### 리베이스
```bash
# main으로 기능 브랜치 업데이트
git fetch origin
git rebase origin/main

# 정리를 위한 인터랙티브 리베이스
git rebase -i HEAD~3
```

### 스태시
```bash
# 현재 변경사항 스태시
git stash push -m "WIP: 사용자 프로필"

# 스태시 목록 확인
git stash list

# 스태시 적용 및 제거
git stash pop
```

## PR 모범 사례

1. PR은 작고 집중적으로 유지 (400줄 미만)
2. 설명적인 PR 제목 작성
3. PR 설명에 컨텍스트 포함
4. 관련 이슈 연결
5. 특정 리뷰어 지정
6. 리뷰 코멘트에 신속하게 응답

### PR 템플릿

```markdown
## 변경 사항
<!-- 변경 내용을 간단히 설명하세요 -->

## 변경 유형
- [ ] 새 기능 (feat)
- [ ] 버그 수정 (fix)
- [ ] 리팩토링 (refactor)
- [ ] 문서 업데이트 (docs)
- [ ] 테스트 추가/수정 (test)
- [ ] 기타 (chore)

## 관련 이슈
<!-- Closes #이슈번호 -->

## 테스트 방법
<!-- 변경 사항을 어떻게 테스트했는지 설명하세요 -->
1.
2.
3.

## 체크리스트
- [ ] 코드가 프로젝트 스타일 가이드를 따름
- [ ] 셀프 리뷰 완료
- [ ] 적절한 테스트 추가/수정
- [ ] 문서 업데이트 (필요한 경우)
- [ ] 관련 변경 사항이 커밋 메시지에 반영됨
```

## 시맨틱 버전 관리

[SemVer](https://semver.org/) 규칙을 따릅니다: `MAJOR.MINOR.PATCH`

| 변경 유형 | 버전 업데이트 | 예시 |
|-----------|-------------|------|
| Breaking change | MAJOR | 1.0.0 → 2.0.0 |
| 새 기능 (하위 호환) | MINOR | 1.0.0 → 1.1.0 |
| 버그 수정 | PATCH | 1.0.0 → 1.0.1 |

### CHANGELOG 형식

```markdown
# Changelog

## [1.2.0] - 2025-01-15

### Added
- OAuth2 소셜 로그인 지원 (#123)
- 사용자 프로필 이미지 업로드 (#125)

### Changed
- 로그인 페이지 UI 개선 (#124)

### Fixed
- 비밀번호 재설정 이메일 발송 오류 (#126)

### Removed
- 레거시 세션 기반 인증 (#127)
```

## GitHub Actions CI/CD

### Python (FastAPI) CI
```yaml
name: Python CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Set up Python
        run: uv python install 3.12

      - name: Install dependencies
        run: uv sync

      - name: Lint
        run: uv run ruff check .

      - name: Format check
        run: uv run ruff format --check .

      - name: Type check
        run: uv run mypy .

      - name: Test
        run: uv run pytest --cov=src --cov-report=xml
```

### TypeScript (React/Next.js) CI
```yaml
name: TypeScript CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm lint

      - name: Type check
        run: pnpm tsc --noEmit

      - name: Test
        run: pnpm test --coverage

      - name: Build
        run: pnpm build
```
