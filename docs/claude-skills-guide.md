# Claude Skills 사용 가이드

## 개요

dev-standards에 통합된 Claude Code 스킬입니다. [kimoring-ai-skills](https://github.com/your-org/kimoring-ai-skills)에서 가져온 메타 검증 스킬로, 코드 품질을 자동으로 검증합니다.

## 포함된 스킬

| Skill | 역할 |
|-------|------|
| `dev-toolkit` | 코드 생성 도구 (API, 컴포넌트, 테스트 보일러플레이트) |
| `manage-skills` | 세션 변경사항 분석 → 검증 스킬 자동 생성/업데이트 |
| `verify-implementation` | 모든 검증 스킬 통합 실행 → 검증 보고서 생성 |

## 프로젝트에 스킬 적용하기

### 방법 1: create-project.sh 사용

```bash
# 스킬 포함하여 프로젝트 생성
./scripts/create-project.sh --name my-project --type fullstack --with-skills

# 스킬 + 코드 생성기 함께 포함
./scripts/create-project.sh --name my-project --type fullstack --with-skills --with-generators
```

### 방법 2: 수동 복사

```bash
# 기존 프로젝트에 스킬 추가
mkdir -p .claude/skills
cp -r /path/to/dev-standards/templates/claude-skills/manage-skills .claude/skills/
cp -r /path/to/dev-standards/templates/claude-skills/verify-implementation .claude/skills/
cp -r /path/to/dev-standards/templates/claude-skills/dev-toolkit .claude/skills/
```

## manage-skills 사용법

### 실행 시점
- 새로운 패턴이나 규칙을 도입하는 기능을 구현한 후
- PR 전에 verify 스킬이 변경된 영역을 커버하는지 확인할 때
- 검증 실행 시 예상했던 이슈를 놓쳤을 때
- 주기적으로 스킬을 코드베이스 변화에 맞춰 정렬할 때

### 워크플로우
1. 세션 변경사항 분석 (`git diff`로 변경 파일 수집)
2. 등록된 스킬과 변경 파일 매핑
3. 영향받은 스킬의 커버리지 갭 분석
4. 새 스킬 CREATE / 기존 스킬 UPDATE 결정
5. 사용자 승인 후 스킬 생성/업데이트
6. 검증 및 요약 보고서 출력

### 사용 예시
```bash
# Claude Code에서 실행
/manage-skills

# 특정 영역에 집중
/manage-skills api
```

## verify-implementation 사용법

### 실행 시점
- 새로운 기능을 구현한 후
- Pull Request를 생성하기 전
- 코드 리뷰 중
- 코드베이스 규칙 준수 여부를 감사할 때

### 보고서 해석

검증 결과는 다음과 같은 형태로 표시됩니다:

```
## 구현 검증 보고서

| 검증 스킬 | 상태 | 이슈 수 |
|-----------|------|---------|
| verify-api | PASS | 0 |
| verify-ui | 2개 이슈 | 2 |
```

- **PASS**: 모든 검사 통과
- **X개 이슈**: 발견된 위반 사항 (파일 경로, 문제 설명, 수정 방법 포함)

### 수정 옵션
이슈 발견 시 3가지 옵션 제공:
1. **전체 수정** - 모든 권장 수정사항을 자동 적용
2. **개별 수정** - 각 수정사항을 하나씩 검토 후 적용
3. **건너뛰기** - 변경 없이 종료

### 사용 예시
```bash
# 전체 검증
/verify-implementation

# 특정 스킬만 실행
/verify-implementation verify-api
```

## 개발 워크플로우 연동

권장 워크플로우:

```
구현 → /manage-skills → /verify-implementation → PR
```

1. **기능 구현**: 코드를 작성합니다
2. **`/manage-skills`**: 변경사항을 분석하여 필요한 검증 스킬을 생성/업데이트합니다
3. **`/verify-implementation`**: 모든 검증 스킬을 실행하여 규칙 준수 여부를 확인합니다
4. **PR 생성**: 모든 검증을 통과한 후 PR을 생성합니다

## 프로젝트별 검증 스킬 예시

`manage-skills`가 프로젝트에 맞게 자동 생성하는 검증 스킬 예시:

| 스킬 | 용도 |
|------|------|
| `verify-api` | API 엔드포인트 규칙 검증 (응답 형식, 에러 처리, 인증) |
| `verify-ui` | UI 컴포넌트 규칙 검증 (네이밍, 구조, 접근성) |
| `verify-test` | 테스트 규칙 검증 (커버리지, 패턴, 네이밍) |
| `verify-auth` | 인증/인가 패턴 검증 |
| `verify-db` | 데이터베이스 접근 패턴 검증 |

이러한 스킬은 `manage-skills`가 코드베이스를 분석하여 자동으로 생성하며, `.claude/skills/verify-<name>/SKILL.md`에 저장됩니다.
