#!/bin/bash

#######################################
# Backend 프로젝트 생성 템플릿
#######################################

# Load dependencies
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_LIB}/ui.sh"
source "${SCRIPT_DIR_LIB}/commitlint.sh"

create_backend() {
    local project_path="$1"
    local project_name="$2"

    print_header "Backend 프로젝트 생성: $project_name"

    # 디렉토리 생성
    print_step "디렉토리 생성..."
    mkdir -p "$project_path"
    cd "$project_path" || return 1

    # 디렉토리 구조 생성
    print_step "디렉토리 구조 생성..."
    mkdir -p src/{domains,shared/{database,patterns,utils}}
    mkdir -p .claude/{agents,commands,scripts}
    mkdir -p docs/prd/{common,endpoints}
    mkdir -p tests/{unit,integration}
    mkdir -p scripts

    # __init__.py 생성
    touch src/__init__.py
    touch src/domains/__init__.py
    touch src/shared/__init__.py
    touch src/shared/database/__init__.py
    touch src/shared/patterns/__init__.py
    touch src/shared/utils/__init__.py
    touch tests/__init__.py
    touch tests/unit/__init__.py
    touch tests/integration/__init__.py

    # pyproject.toml
    print_step "pyproject.toml 생성..."
    cat > pyproject.toml << EOF
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "$project_name"
version = "0.1.0"
description = "$project_name - FastAPI Backend"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.111.0",
    "uvicorn[standard]>=0.29.0",
    "asyncpg>=0.29.0",
    "pydantic>=2.7.0",
    "pydantic-settings>=2.2.0",
    "python-dotenv>=1.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.27.0",
    "ruff>=0.4.0",
    "mypy>=1.10.0",
]

[tool.hatch.build.targets.wheel]
packages = ["src"]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "ARG", "SIM", "TCH", "PTH", "ERA", "PL", "RUF", "ASYNC", "S"]
ignore = ["E501", "PLR0913", "PLR2004"]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["S101", "ARG"]

[tool.ruff.lint.isort]
known-first-party = ["src"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
EOF

    # src/main.py
    print_step "main.py 생성..."
    cat > src/main.py << 'MAINPY'
"""FastAPI 애플리케이션 진입점."""

from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.shared.database import db_pool


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """애플리케이션 생명주기 관리."""
    await db_pool.initialize()
    yield
    await db_pool.close()


app = FastAPI(
    title="API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 도메인 라우터 등록
# from src.domains.example import router as example_router
# app.include_router(example_router)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """헬스 체크 엔드포인트."""
    return {"status": "healthy"}
MAINPY

    # Database modules
    print_step "Database 모듈 생성..."
    cat > src/shared/database/connection.py << 'DBCONNPY'
"""Database connection management."""

from contextlib import asynccontextmanager
from typing import AsyncIterator

import asyncpg
from pydantic_settings import BaseSettings


class DatabaseSettings(BaseSettings):
    """Database connection settings."""

    primary_db_url: str = "postgresql://user:password@localhost:5432/appdb"
    replica_db_url: str | None = None

    class Config:
        env_prefix = "DB_"


class DatabasePool:
    """Manages database connection pools."""

    def __init__(self) -> None:
        self._primary_pool: asyncpg.Pool | None = None
        self._replica_pool: asyncpg.Pool | None = None
        self._settings = DatabaseSettings()

    async def initialize(self) -> None:
        """Initialize database connection pools."""
        self._primary_pool = await asyncpg.create_pool(
            self._settings.primary_db_url,
            min_size=5,
            max_size=20,
            command_timeout=60,
        )
        if self._settings.replica_db_url:
            self._replica_pool = await asyncpg.create_pool(
                self._settings.replica_db_url,
                min_size=5,
                max_size=20,
                command_timeout=60,
            )

    async def close(self) -> None:
        """Close all database connection pools."""
        if self._primary_pool:
            await self._primary_pool.close()
        if self._replica_pool:
            await self._replica_pool.close()

    @asynccontextmanager
    async def acquire_primary(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection from the primary pool."""
        if not self._primary_pool:
            raise RuntimeError("Database pool not initialized")
        async with self._primary_pool.acquire() as connection:
            yield connection

    @asynccontextmanager
    async def acquire_replica(self) -> AsyncIterator[asyncpg.Connection]:
        """Acquire a connection from the replica pool."""
        pool = self._replica_pool or self._primary_pool
        if not pool:
            raise RuntimeError("Database pool not initialized")
        async with pool.acquire() as connection:
            yield connection


db_pool = DatabasePool()


async def get_db_connection() -> AsyncIterator[asyncpg.Connection]:
    """FastAPI dependency for database connection."""
    async with db_pool.acquire_primary() as connection:
        yield connection


async def get_readonly_connection() -> AsyncIterator[asyncpg.Connection]:
    """FastAPI dependency for read-only database connection."""
    async with db_pool.acquire_replica() as connection:
        yield connection
DBCONNPY

    cat > src/shared/database/transaction.py << 'DBTXPY'
"""Transaction management utilities."""

from contextlib import asynccontextmanager
from typing import AsyncIterator

import asyncpg


@asynccontextmanager
async def transaction(
    connection: asyncpg.Connection,
    isolation: str = "read_committed",
) -> AsyncIterator[asyncpg.Connection]:
    """Context manager for database transactions."""
    async with connection.transaction(isolation=isolation):
        yield connection


@asynccontextmanager
async def savepoint(
    connection: asyncpg.Connection,
    name: str | None = None,
) -> AsyncIterator[asyncpg.Connection]:
    """Context manager for savepoints within a transaction."""
    if name:
        await connection.execute(f"SAVEPOINT {name}")
        try:
            yield connection
            await connection.execute(f"RELEASE SAVEPOINT {name}")
        except Exception:
            await connection.execute(f"ROLLBACK TO SAVEPOINT {name}")
            raise
    else:
        async with connection.transaction():
            yield connection
DBTXPY

    cat > src/shared/database/__init__.py << 'DBINITPY'
"""Database utilities package."""

from .connection import (
    DatabasePool,
    db_pool,
    get_db_connection,
    get_readonly_connection,
)
from .transaction import savepoint, transaction

__all__ = [
    "DatabasePool",
    "db_pool",
    "get_db_connection",
    "get_readonly_connection",
    "savepoint",
    "transaction",
]
DBINITPY

    # Utility modules
    cat > src/shared/utils/sql_loader.py << 'SQLLOADERPY'
"""SQL file loader utility."""

from functools import lru_cache
from pathlib import Path


class SQLLoader:
    """Loads and caches SQL files from a domain's sql directory."""

    def __init__(self, domain: str, base_path: Path | None = None) -> None:
        self.domain = domain
        if base_path is None:
            base_path = Path(__file__).parent.parent.parent / "domains"
        self.sql_path = base_path / domain / "sql"

    @lru_cache(maxsize=100)
    def load(self, filename: str) -> str:
        """Load a SQL file and cache the result."""
        file_path = self.sql_path / filename
        if not file_path.exists():
            raise FileNotFoundError(f"SQL file not found: {file_path}")
        return file_path.read_text(encoding="utf-8").strip()


def create_sql_loader(domain: str) -> SQLLoader:
    """Create a SQL loader for a specific domain."""
    return SQLLoader(domain)
SQLLOADERPY

    cat > src/shared/utils/__init__.py << 'UTILSINITPY'
"""Shared utilities package."""

from .sql_loader import SQLLoader, create_sql_loader

__all__ = ["SQLLoader", "create_sql_loader"]
UTILSINITPY

    # Tests
    print_step "테스트 설정 생성..."
    cat > tests/conftest.py << 'CONFTESTPY'
"""pytest fixtures."""

from collections.abc import AsyncGenerator
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from src.main import app


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    """Test HTTP client."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac


@pytest.fixture
def mock_repository() -> MagicMock:
    """Mock repository for unit tests."""
    return MagicMock()


@pytest.fixture
def sample_data() -> dict[str, Any]:
    """Sample test data."""
    return {
        "id": 1,
        "name": "Test Item",
        "created_at": "2024-01-01T00:00:00Z",
    }
CONFTESTPY

    # Environment files
    cat > .env.example << ENVEOF
DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@localhost:5432/$project_name
# DB_REPLICA_DB_URL=postgresql://devuser:devpassword@localhost:5432/${project_name}_replica
ENV=development
DEBUG=true
ENVEOF

    echo "3.11" > .python-version

    # .gitignore
    cat > .gitignore << 'GITIGNORE'
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.venv/
venv/
.pytest_cache/
.coverage
htmlcov/
.mypy_cache/
.env
.env.local
.DS_Store
*.log
GITIGNORE

    # Docker files
    print_step "Dockerfile 생성..."
    cat > Dockerfile << 'DOCKERFILE'
FROM python:3.11-slim

WORKDIR /app

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY pyproject.toml ./
RUN pip install --no-cache-dir uv && \
    uv pip install --system -e .

# 소스 코드 복사
COPY src/ ./src/

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
DOCKERFILE

    cat > docker-compose.yml << 'DOCKERCOMPOSE'
services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DB_PRIMARY_DB_URL=postgresql://devuser:devpassword@db:5432/appdb
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./src:/app/src
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
DOCKERCOMPOSE

    # Copy templates
    print_step "PRD 템플릿 복사..."
    if [ -d "$STANDARDS_PATH/templates/prd" ]; then
        cp "$STANDARDS_PATH/templates/prd/common.md" docs/prd/common/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/prd/endpoint.md" docs/prd/endpoints/_template.md 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/prd/index.md" docs/prd/ 2>/dev/null || true
    fi

    print_step "Claude Code 설정 복사..."
    if [ -d "$STANDARDS_PATH/templates/claude-agents" ]; then
        cp "$STANDARDS_PATH/templates/claude-agents/fastapi-specialist.md" .claude/agents/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/sql-query-specialist.md" .claude/agents/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/claude-agents/api-test-specialist.md" .claude/agents/ 2>/dev/null || true
    fi

    if [ -d "$STANDARDS_PATH/templates/hooks/backend" ]; then
        cp "$STANDARDS_PATH/templates/hooks/backend/check-env.sh" .claude/scripts/ 2>/dev/null || true
        chmod +x .claude/scripts/check-env.sh 2>/dev/null || true
    fi

    print_step "API 응답 포맷 템플릿 복사..."
    if [ -d "$STANDARDS_PATH/templates/backend" ]; then
        mkdir -p src/shared/response
        cp "$STANDARDS_PATH/templates/backend/response_schemas.py" src/shared/response/ 2>/dev/null || true
        cp "$STANDARDS_PATH/templates/backend/response_utils.py" src/shared/response/ 2>/dev/null || true
        touch src/shared/response/__init__.py
        cat > src/shared/response/__init__.py << 'RESPONSEINITPY'
"""API 응답 포맷 유틸리티."""

from .response_schemas import (
    ErrorDetail,
    ErrorInfo,
    ErrorResponse,
    PaginatedData,
    PaginationInfo,
    ResponseMeta,
    SuccessResponse,
)
from .response_utils import error_response, success_response

__all__ = [
    "ErrorDetail",
    "ErrorInfo",
    "ErrorResponse",
    "PaginatedData",
    "PaginationInfo",
    "ResponseMeta",
    "SuccessResponse",
    "error_response",
    "success_response",
]
RESPONSEINITPY
    fi

    print_step "개발 표준 문서 복사..."
    mkdir -p docs/standards
    if [ -d "$STANDARDS_PATH/docs" ]; then
        cp "$STANDARDS_PATH/docs/git-workflow.md" docs/standards/ 2>/dev/null || true
        cp "$STANDARDS_PATH/docs/commit-convention.md" docs/standards/ 2>/dev/null || true
    fi
    if [ -d "$STANDARDS_PATH/templates/workflows" ]; then
        cp "$STANDARDS_PATH/templates/workflows/development-workflow.md" docs/standards/ 2>/dev/null || true
    fi

    # CLAUDE.md
    print_step "CLAUDE.md 생성..."
    cat > CLAUDE.md << 'CLAUDEMD'
# CLAUDE.md - Backend Project

## 필수 참조 문서
**중요**: 코드 작성 전 반드시 아래 문서를 읽고 규칙을 준수하세요.
- `docs/standards/git-workflow.md` - Git 브랜치 전략, 커밋 규칙
- `docs/standards/commit-convention.md` - 커밋 메시지 컨벤션
- `docs/standards/development-workflow.md` - 개발 워크플로우

## 핵심 규칙 요약

### Git 규칙
- 브랜치: `master` → `SKTL-XXXX` (JIRA 티켓) → `develop` → `master`
- 로컬에서 master 직접 push/merge 금지
- 커밋 메시지: `type(scope): description` 형식

### 코드 규칙
- 새 도메인은 `src/domains/{도메인}/` 하위에 작성
- 레이어 패턴 준수: Router → Service → Repository
- SQL은 `sql/` 폴더에 파일로 분리
- ORM 사용 금지, 순수 SQL + asyncpg 사용

### 트랜잭션 규칙
- Service 레벨에서 트랜잭션 관리
- Repository는 connection만 받아서 사용 (트랜잭션 시작 금지)
- 복수 DB 작업 시 Saga 패턴 사용

### 테스트 규칙
- 단위 테스트: `tests/unit/`
- 통합 테스트: `tests/integration/`
- AAA 패턴 (Arrange-Act-Assert) 사용

CLAUDEMD

    cat >> CLAUDE.md << CLAUDEMDEOF

## 프로젝트 정보

**프로젝트명**: $project_name

## 기술 스택
- **Framework**: FastAPI
- **Database**: PostgreSQL
- **Driver**: asyncpg
- **Validation**: Pydantic v2
- **Python**: 3.11+

## 개발 명령어

\`\`\`bash
# 개발 서버
uvicorn src.main:app --reload --port 8000

# 린트
ruff check src tests

# 포맷팅
ruff format src tests

# 타입 체크
mypy src

# 테스트
pytest
pytest --cov=src
\`\`\`

## 프로젝트 구조

\`\`\`
src/
├── domains/              # 업무 도메인
│   └── {domain}/
│       ├── router.py     # API 엔드포인트
│       ├── service.py    # 비즈니스 로직
│       ├── repository.py # 데이터 접근
│       ├── schemas.py    # Pydantic 스키마
│       └── sql/          # SQL 파일
├── shared/
│   ├── database/         # DB 연결, 트랜잭션
│   └── utils/            # 유틸리티
└── main.py
\`\`\`

## Claude Code Agents

- \`@fastapi-specialist\` - FastAPI API 설계
- \`@sql-query-specialist\` - PostgreSQL 쿼리
- \`@api-test-specialist\` - pytest API 테스트

## 문서
- [Git 워크플로우](docs/standards/git-workflow.md)
- [커밋 컨벤션](docs/standards/commit-convention.md)
- [개발 워크플로우](docs/standards/development-workflow.md)
CLAUDEMDEOF

    # README.md
    cat > README.md << READMEEOF
# $project_name

FastAPI + PostgreSQL 기반 백엔드 프로젝트입니다.

## 시작하기

\`\`\`bash
# 가상환경 생성
python -m venv .venv
source .venv/bin/activate

# 의존성 설치
uv pip install -e ".[dev]"

# 환경 변수 설정
cp .env.example .env

# 개발 서버 실행
uvicorn src.main:app --reload --port 8000
\`\`\`

## 기술 스택

- FastAPI
- PostgreSQL + asyncpg
- Pydantic v2
- Python 3.11+

## 문서

- [CLAUDE.md](CLAUDE.md) - Claude Code 가이드
- [Git 워크플로우](docs/standards/git-workflow.md)
- [커밋 컨벤션](docs/standards/commit-convention.md)
- [개발 워크플로우](docs/standards/development-workflow.md)
READMEEOF

    # Commitlint setup
    setup_commitlint "$project_path" "uv"

    # Claude Skills
    if [ "$PROJECT_WITH_SKILLS" = true ]; then
        print_step "Claude Skills 복사..."
        mkdir -p .claude/skills
        cp -r "$STANDARDS_PATH/templates/claude-skills/manage-skills" .claude/skills/
        cp -r "$STANDARDS_PATH/templates/claude-skills/verify-implementation" .claude/skills/
        cp -r "$STANDARDS_PATH/templates/claude-skills/dev-toolkit" .claude/skills/
    fi

    # Code Generators
    if [ "$PROJECT_WITH_GENERATORS" = true ]; then
        print_step "Code Generators 복사..."
        mkdir -p scripts/generators
        cp "$STANDARDS_PATH/scripts/generators/"*.py scripts/generators/
        cp "$STANDARDS_PATH/scripts/generators/__init__.py" scripts/generators/ 2>/dev/null || touch scripts/generators/__init__.py
        mkdir -p templates/code-generators
        cp "$STANDARDS_PATH/templates/code-generators/"* templates/code-generators/
    fi

    print_success "Backend 프로젝트 생성 완료: $project_path"
}
