# Claude Code Hooks 가이드

## 개요
Claude Code Hooks를 사용하여 환경 버전 강제, 코드 품질 체크 등을 자동화할 수 있습니다.

---

## 환경 버전 강제 설정

### 1. 설정 파일 구조

```
project/
├── .claude/
│   ├── settings.json    # hooks 설정
│   └── scripts/
│       └── check-env.sh # 버전 체크 스크립트
├── .node-version        # Node.js 버전 (nvm/fnm용)
├── .nvmrc               # Node.js 버전 (nvm용)
└── .python-version      # Python 버전 (pyenv용)
```

### 2. settings.json 설정

**Frontend 프로젝트**
```json
{
  "hooks": {
    "PreToolCall": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/check-env.sh"
          }
        ]
      }
    ]
  }
}
```

**Backend 프로젝트**
```json
{
  "hooks": {
    "PreToolCall": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/check-env.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. Hook 동작 방식

| Hook 타입 | 실행 시점 | 용도 |
|-----------|----------|------|
| `PreToolCall` | 도구 호출 전 | 환경 체크, 권한 확인 |
| `PostToolCall` | 도구 호출 후 | 로깅, 결과 검증 |
| `Notification` | 알림 발생 시 | 외부 시스템 연동 |

### 4. Matcher 옵션

```json
{
  "matcher": "Bash"           // Bash 명령 실행 전
}
{
  "matcher": "Write"          // 파일 쓰기 전
}
{
  "matcher": "Edit"           // 파일 편집 전
}
{
  "matcher": {                // 조건부 매칭
    "tool": "Bash",
    "command": "npm|pnpm|yarn"
  }
}
```

---

## 버전 체크 스크립트

### Frontend (check-env.sh)

```bash
#!/bin/bash
set -e

REQUIRED_NODE_MAJOR=20
REQUIRED_PNPM_MAJOR=9

# Node.js 버전 체크
NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt "$REQUIRED_NODE_MAJOR" ]; then
    echo "[ERROR] Node.js ${REQUIRED_NODE_MAJOR}.x 이상 필요"
    exit 1
fi

# pnpm 체크 (선택)
if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm -v | cut -d. -f1)
    if [ "$PNPM_VERSION" -lt "$REQUIRED_PNPM_MAJOR" ]; then
        echo "[WARNING] pnpm ${REQUIRED_PNPM_MAJOR}.x 권장"
    fi
fi

exit 0
```

### Backend (check-env.sh)

지원 환경: **venv**, **pyenv**, **conda**

```bash
#!/bin/bash
set -e

REQUIRED_PYTHON_MAJOR=3
REQUIRED_PYTHON_MINOR=11

# 환경 감지: conda > pyenv > venv > system
detect_python_env() {
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        echo "conda"
    elif [ -n "$PYENV_VERSION" ] || [ -n "$PYENV_VIRTUAL_ENV" ]; then
        echo "pyenv"
    elif [ -n "$VIRTUAL_ENV" ]; then
        echo "venv"
    else
        echo "system"
    fi
}

# 환경별 Python 버전 가져오기
env_type=$(detect_python_env)
case $env_type in
    conda|pyenv|venv)
        PYTHON_VERSION=$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        ;;
    system)
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        ;;
esac

PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

echo "[ENV] $env_type - Python $PYTHON_VERSION"

if [ "$PYTHON_MAJOR" -lt "$REQUIRED_PYTHON_MAJOR" ] || \
   ([ "$PYTHON_MAJOR" -eq "$REQUIRED_PYTHON_MAJOR" ] && [ "$PYTHON_MINOR" -lt "$REQUIRED_PYTHON_MINOR" ]); then
    echo "[ERROR] Python ${REQUIRED_PYTHON_MAJOR}.${REQUIRED_PYTHON_MINOR} 이상 필요"

    # 환경별 해결 방법 안내
    case $env_type in
        conda)  echo "conda create -n myenv python=3.11" ;;
        pyenv)  echo "pyenv install 3.11 && pyenv local 3.11" ;;
        venv)   echo "python3.11 -m venv .venv && source .venv/bin/activate" ;;
    esac
    exit 1
fi

# 가상환경 미사용 경고
if [ "$env_type" = "system" ]; then
    if [ -d ".venv" ]; then
        echo "[WARNING] source .venv/bin/activate"
    elif [ -f ".python-version" ]; then
        echo "[WARNING] pyenv가 활성화되지 않았습니다"
    elif [ -f "environment.yml" ]; then
        echo "[WARNING] conda 환경이 활성화되지 않았습니다"
    fi
fi

exit 0
```

---

## 추가 Hook 활용 예시

### 1. 민감 파일 쓰기 방지

```json
{
  "hooks": {
    "PreToolCall": [
      {
        "matcher": {
          "tool": "Write",
          "path": ".*\\.(env|pem|key)$"
        },
        "hooks": [
          {
            "type": "command",
            "command": "echo '[ERROR] 민감 파일 쓰기 금지' && exit 1"
          }
        ]
      }
    ]
  }
}
```

### 2. 특정 브랜치 보호

```json
{
  "hooks": {
    "PreToolCall": [
      {
        "matcher": {
          "tool": "Bash",
          "command": "git (push|merge).*master"
        },
        "hooks": [
          {
            "type": "command",
            "command": "echo '[ERROR] master 직접 push/merge 금지' && exit 1"
          }
        ]
      }
    ]
  }
}
```

### 3. 코드 포맷팅 자동 실행

```json
{
  "hooks": {
    "PostToolCall": [
      {
        "matcher": {
          "tool": "Write",
          "path": ".*\\.(ts|tsx)$"
        },
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write $CLAUDE_FILE_PATH"
          }
        ]
      }
    ]
  }
}
```

---

## 설정 적용 방법

### 신규 프로젝트

```bash
# 1. 템플릿에서 복사
cp dev-standards/templates/hooks/frontend/settings.json .claude/
cp dev-standards/templates/hooks/frontend/check-env.sh .claude/scripts/

# 2. 실행 권한 부여
chmod +x .claude/scripts/check-env.sh

# 3. 버전 파일 생성
echo "20" > .node-version
echo "20" > .nvmrc
```

### 기존 프로젝트

```bash
# 1. .claude 디렉토리 생성
mkdir -p .claude/scripts

# 2. 설정 파일 복사
cp dev-standards/templates/hooks/{frontend|backend}/settings.json .claude/
cp dev-standards/templates/hooks/{frontend|backend}/check-env.sh .claude/scripts/

# 3. 실행 권한 부여
chmod +x .claude/scripts/check-env.sh
```

---

## 트러블슈팅

### Hook이 실행되지 않는 경우
1. `.claude/settings.json` 경로 확인
2. 스크립트 실행 권한 확인: `chmod +x .claude/scripts/*.sh`
3. JSON 문법 오류 확인

### 버전 체크 우회가 필요한 경우
```bash
# 일시적으로 hook 비활성화 (settings.json 수정)
# 또는 스크립트에서 특정 조건 예외 처리
```

### 디버깅
```bash
# 스크립트 직접 실행하여 테스트
.claude/scripts/check-env.sh
echo $?  # 0이면 성공, 1이면 실패
```
