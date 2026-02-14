#!/bin/bash

#######################################
# Fullstack 프로젝트 생성 템플릿
#######################################

# Load dependencies
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_LIB}/ui.sh"
source "${SCRIPT_DIR_LIB}/templates-frontend.sh"
source "${SCRIPT_DIR_LIB}/templates-backend.sh"

create_fullstack() {
    local base_path="$1"
    local project_name="$2"
    local frontend_dir="$3"
    local backend_dir="$4"

    # 기본값 설정
    if [ -z "$frontend_dir" ]; then
        frontend_dir="$project_name-frontend"
    fi
    if [ -z "$backend_dir" ]; then
        backend_dir="$project_name-backend"
    fi

    print_header "Fullstack 프로젝트 생성: $project_name"
    echo -e "  Frontend: ${GREEN}$frontend_dir${NC}"
    echo -e "  Backend:  ${GREEN}$backend_dir${NC}"

    # 루트 디렉토리 생성
    mkdir -p "$base_path"

    # Frontend 생성
    create_frontend "$base_path/$frontend_dir" "$frontend_dir"

    # Backend 생성
    create_backend "$base_path/$backend_dir" "$backend_dir"

    # 루트 docker-compose.yml 생성
    print_step "루트 docker-compose.yml 생성..."
    cat > "$base_path/docker-compose.yml" << EOF
services:
  frontend:
    build:
      context: ./$frontend_dir
      dockerfile: Dockerfile.dev
    ports:
      - "5173:5173"
    depends_on:
      - backend
    volumes:
      - ./$frontend_dir/src:/app/src
      - ./$frontend_dir/package.json:/app/package.json
      - /app/node_modules

  backend:
    build:
      context: ./$backend_dir
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@db:5432/appdb
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./$backend_dir/src:/app/src
    command: uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=devuser
      - POSTGRES_PASSWORD=devpassword
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U devuser -d appdb"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
EOF

    # Fullstack Team 설정: 모든 Agent + Team 템플릿을 양쪽에 복사
    print_step "Fullstack Team 템플릿 설정..."
    if [ -d "$STANDARDS_PATH/templates/claude-agents" ]; then
        # Frontend에 Backend Agent 추가
        cp "$STANDARDS_PATH/templates/claude-agents/fastapi-specialist.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/sql-query-specialist.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/api-test-specialist.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true

        # Backend에 Frontend Agent 추가
        cp "$STANDARDS_PATH/templates/claude-agents/react-specialist.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/e2e-test-specialist.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/code-quality-reviewer.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
    fi

    # Team Lead 템플릿을 양쪽에 복사
    if [ -d "$STANDARDS_PATH/templates/claude-teams" ]; then
        cp "$STANDARDS_PATH/templates/claude-teams/fullstack-team.md" "$base_path/$frontend_dir/.claude/agents/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-teams/fullstack-team.md" "$base_path/$backend_dir/.claude/agents/" 2>/dev/null || true
    fi

    # Fullstack Team 가이드 복사
    if [ -d "$STANDARDS_PATH/templates/workflows" ]; then
        cp "$STANDARDS_PATH/templates/workflows/fullstack-team-guide.md" "$base_path/$frontend_dir/docs/standards/" 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/workflows/fullstack-team-guide.md" "$base_path/$backend_dir/docs/standards/" 2>/dev/null || true
    fi

    print_success "Team 템플릿 설정 완료 (양쪽 프로젝트에 전체 Agent + Team Lead 복사)"

    # Frontend CLAUDE.md에 Team 정보 추가
    cat >> "$base_path/$frontend_dir/CLAUDE.md" << 'FRONTENDTEAM'

## Claude Code Team

- `@fullstack-team` - Fullstack 기능 병렬 개발 (Backend + Frontend + Test + Review)

### Team 사용 예시
```bash
@fullstack-team 매출 목록 페이지 구현
```

자세한 사용법은 [Fullstack Team Guide](docs/standards/fullstack-team-guide.md) 참조
FRONTENDTEAM

    # Backend CLAUDE.md에 Team 정보 추가
    cat >> "$base_path/$backend_dir/CLAUDE.md" << 'BACKENDTEAM'

## Claude Code Team

- `@fullstack-team` - Fullstack 기능 병렬 개발 (Backend + Frontend + Test + Review)

### Team 사용 예시
```bash
@fullstack-team 매출 목록 페이지 구현
```

자세한 사용법은 [Fullstack Team Guide](docs/standards/fullstack-team-guide.md) 참조
BACKENDTEAM

    # 루트 README.md 생성
    cat > "$base_path/README.md" << EOF
# $project_name

Fullstack 프로젝트 (Frontend + Backend)

## 구조

\`\`\`
$project_name/
├── $frontend_dir/     # React + TypeScript
├── $backend_dir/      # FastAPI + PostgreSQL
└── docker-compose.yml # 통합 실행
\`\`\`

## 시작하기

### Docker로 전체 실행
\`\`\`bash
docker-compose up -d
\`\`\`

### 개별 실행

**Frontend:**
\`\`\`bash
cd $frontend_dir
pnpm install
pnpm dev
\`\`\`

**Backend:**
\`\`\`bash
cd $backend_dir
python -m venv .venv
source .venv/bin/activate
uv pip install -e ".[dev]"
uvicorn src.main:app --reload --port 8000
\`\`\`

## Claude Code Team

Fullstack 기능을 병렬로 개발하려면:
\`\`\`bash
# Frontend 또는 Backend 디렉토리에서
@fullstack-team 매출 목록 페이지 구현
\`\`\`

## 접속 URL

- Frontend: http://localhost:5173 (개발) / http://localhost:80 (Docker)
- Backend API: http://localhost:8000
- API 문서: http://localhost:8000/docs
EOF

    print_success "Fullstack 프로젝트 생성 완료: $base_path"
}
