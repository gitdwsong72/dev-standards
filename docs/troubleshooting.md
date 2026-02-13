# Troubleshooting

자주 발생하는 문제와 해결 방법을 정리합니다.

---

## 1. ESLint 설정 관련

### 1.1 "ESLint couldn't find the config" 오류

**증상:**
```
ESLint couldn't find the config "eslint.config.js" to extend from.
```

**원인:** ESLint 9+ Flat Config를 사용하지만, 프로젝트에 `eslint.config.js`가 없거나 `.eslintrc` 형식을 사용 중

**해결:**
```javascript
// eslint.config.js (프로젝트 루트에 생성)
import config from '@company/eslint-config/react';
export default config;
```

### 1.2 "Cannot find module '@company/eslint-config'" 오류

**증상:**
```
Error: Cannot find module '@company/eslint-config'
```

**원인:** 패키지가 설치되지 않았거나, npm 레지스트리 설정이 잘못됨

**해결:**
```bash
# 패키지 설치 확인
pnpm ls @company/eslint-config

# 재설치
pnpm add -D @company/eslint-config

# .npmrc 확인 (사내 레지스트리 사용 시)
cat .npmrc
# @company:registry=https://your-registry.com
```

### 1.3 ESLint와 Prettier 충돌

**증상:** ESLint가 Prettier로 포맷된 코드를 에러로 보고

**원인:** ESLint 포맷팅 규칙과 Prettier 설정 불일치

**해결:**
```bash
# @company/eslint-config는 포맷팅 규칙을 포함하지 않으므로
# 일반적으로 충돌하지 않습니다.
# 커스텀 규칙을 추가한 경우 확인하세요:
pnpm eslint --print-config src/App.tsx | grep -i "indent\|semi\|quote"
```

---

## 2. TypeScript 설정 관련

### 2.1 Path Alias가 작동하지 않음

**증상:**
```
Cannot find module '@/components/Button' or its corresponding type declarations.
```

**원인:** `tsconfig.json`의 `paths`와 빌드 도구의 alias 설정 불일치

**해결:**
```json
// tsconfig.json
{
  "extends": "@company/typescript-config/react",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["src/shared/*"],
      "@domains/*": ["src/domains/*"]
    }
  }
}
```

```typescript
// vite.config.ts (Vite에서도 동일하게 설정)
import path from 'path';

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@shared': path.resolve(__dirname, './src/shared'),
      '@domains': path.resolve(__dirname, './src/domains'),
    },
  },
});
```

### 2.2 "verbatimModuleSyntax" 관련 오류

**증상:**
```
error TS1484: 'SomeType' is a type and must be imported using a type-only import
```

**원인:** `@company/typescript-config`의 `verbatimModuleSyntax: true` 설정

**해결:**
```typescript
// Before (에러)
import { SomeType } from './types';

// After (수정)
import type { SomeType } from './types';

// 또는 mixed import
import { someFunction, type SomeType } from './module';
```

---

## 3. Python/Backend 관련

### 3.1 uv가 설치되어 있지 않음

**증상:**
```
command not found: uv
```

**해결:**
```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# pip로 설치
pip install uv

# 설치 후 셸 재시작
source ~/.zshrc  # 또는 source ~/.bashrc
```

### 3.2 asyncpg 연결 오류

**증상:**
```
asyncpg.exceptions.InvalidCatalogNameError: database "appdb" does not exist
```

**원인:** PostgreSQL에 데이터베이스가 생성되지 않음

**해결:**
```bash
# Docker 사용 시
docker-compose up -d db

# 수동 생성 시
psql -U postgres -c "CREATE DATABASE appdb;"

# .env 파일 확인
cat .env
# DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@localhost:5432/appdb
```

### 3.3 Ruff 설정 상속 오류

**증상:**
```
error: Failed to parse path/to/ruff.toml
```

**원인:** `extend` 경로가 잘못되었거나 파일이 존재하지 않음

**해결:**
```toml
# pyproject.toml
[tool.ruff]
# 절대 경로 또는 pyproject.toml 기준 상대 경로 사용
extend = "./path/to/company_standards/ruff.toml"

# company-python-standards 패키지 설치 후 경로 확인
python -c "import company_standards; print(company_standards.__path__)"
```

---

## 4. Docker 관련

### 4.1 Frontend 빌드 시 node_modules 볼륨 충돌

**증상:** Docker에서 `pnpm install` 후에도 모듈을 찾지 못함

**원인:** 호스트 `node_modules`와 컨테이너 `node_modules` 충돌

**해결:**
```yaml
# docker-compose.yml
services:
  frontend:
    volumes:
      - ./src:/app/src
      - ./package.json:/app/package.json
      - /app/node_modules        # 익명 볼륨으로 격리
```

### 4.2 Backend DB 연결 실패 (docker-compose)

**증상:**
```
Connection refused: localhost:5432
```

**원인:** Docker 네트워크에서 `localhost`는 컨테이너 자신을 가리킴

**해결:**
```yaml
# docker-compose.yml에서 서비스 이름 사용
environment:
  - DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@db:5432/appdb
  #                                                     ^^ localhost 대신 서비스명

# healthcheck으로 DB 준비 대기
depends_on:
  db:
    condition: service_healthy
```

---

## 5. Git 워크플로우 관련

### 5.1 master에 실수로 push한 경우

**증상:**
```
remote: error: GH006: Protected branch update failed
```

또는 push가 성공한 경우

**해결:**
```bash
# pre-push hook이 설정되어 있다면 자동 차단됨
# hook이 없었다면:

# 1. 팀에 즉시 알림
# 2. GitHub에서 branch protection 규칙 확인
# 3. 필요시 관리자가 revert
```

**예방:**
```bash
# pre-push hook 설정 (git-workflow.md 참조)
cp templates/git/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

### 5.2 rebase 중 충돌 해결

**증상:** `git rebase origin/master` 중 충돌 발생

**해결:**
```bash
# 1. 충돌 파일 확인
git status

# 2. 충돌 해결 (에디터에서 수정)

# 3. 해결된 파일 추가
git add <resolved-files>

# 4. rebase 계속
git rebase --continue

# 5. 중단하고 싶은 경우
git rebase --abort

# 6. 완료 후 force push (본인 브랜치만!)
git push --force-with-lease
```

### 5.3 커밋 메시지 컨벤션 오류

**증상:** commitlint 검사 실패

**해결:**
```bash
# 올바른 형식
git commit -m "feat(user): add login page"
git commit -m "fix(cart): resolve quantity update issue"

# 틀린 형식 (대문자, 마침표, 과거형 등)
# feat(user): Added login page.  ← 과거형 + 마침표
# Fix: something                 ← scope 누락 + 대문자

# 커밋 메시지 수정 (최근 1개)
git commit --amend -m "feat(user): add login page"
```

---

## 6. Claude Code Agent 관련

### 6.1 Agent 템플릿을 찾을 수 없음

**증상:** `@react-specialist` 호출 시 Agent를 인식하지 못함

**원인:** `.claude/agents/` 디렉토리에 Agent 파일이 없음

**해결:**
```bash
# 프로젝트에 Agent 템플릿 복사
mkdir -p .claude/agents

# Frontend Agent
cp path/to/dev-standards/templates/claude-agents/react-specialist.md .claude/agents/
cp path/to/dev-standards/templates/claude-agents/e2e-test-specialist.md .claude/agents/

# Backend Agent
cp path/to/dev-standards/templates/claude-agents/fastapi-specialist.md .claude/agents/
cp path/to/dev-standards/templates/claude-agents/sql-query-specialist.md .claude/agents/

# 또는 create-project.sh로 새 프로젝트 생성 시 자동 포함
```

### 6.2 Fullstack Team이 정상 작동하지 않음

**증상:** Team 실행 시 일부 Agent가 실행되지 않음

**원인:** Team 정의 파일과 개별 Agent 파일이 모두 필요

**해결:**
```bash
# Team Lead + 모든 Agent 템플릿 복사 확인
ls .claude/agents/
# fullstack-team.md          (Team Lead)
# fastapi-specialist.md      (Backend)
# sql-query-specialist.md    (SQL)
# react-specialist.md        (Frontend)
# api-test-specialist.md     (Test)
# code-quality-reviewer.md   (Review)
```

---

## 7. create-project.sh 관련

### 7.1 스크립트 실행 권한 오류

**증상:**
```
bash: ./scripts/create-project.sh: Permission denied
```

**해결:**
```bash
chmod +x scripts/create-project.sh
./scripts/create-project.sh
```

### 7.2 프로젝트 이름 검증 실패

**증상:**
```
프로젝트명은 영문자, 숫자, 하이픈(-), 언더스코어(_)만 사용 가능합니다.
```

**해결:**
```bash
# 올바른 이름
./scripts/create-project.sh -n my-project -t fullstack
./scripts/create-project.sh -n sales_app -t frontend

# 틀린 이름 (특수문자, 한글, 숫자로 시작)
# ./scripts/create-project.sh -n my.project     ← 점 포함
# ./scripts/create-project.sh -n 123-project    ← 숫자로 시작
```

---

## 디버깅 팁

### ESLint 디버깅
```bash
# 특정 파일의 적용된 규칙 확인
pnpm eslint --print-config src/App.tsx

# 디버그 모드 실행
DEBUG=eslint:* pnpm eslint src/
```

### TypeScript 디버깅
```bash
# tsconfig 해석 결과 확인
pnpm tsc --showConfig

# 타입 에러만 확인 (빌드 없이)
pnpm tsc --noEmit
```

### Ruff 디버깅
```bash
# 적용된 설정 확인
ruff check --show-settings

# 특정 규칙만 확인
ruff check src/ --select E501
```

### Docker 디버깅
```bash
# 컨테이너 로그 확인
docker-compose logs -f backend

# 컨테이너 내부 접속
docker-compose exec backend bash

# 네트워크 확인
docker network ls
docker network inspect <network-name>
```
