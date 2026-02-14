# 코딩 패턴 참조

## Python 패턴

### FastAPI 라우터 구조
```python
from fastapi import APIRouter, Depends, HTTPException, status

router = APIRouter(prefix="/api/v1/items", tags=["items"])

@router.get("/", response_model=list[ItemResponse])
async def list_items(db: Session = Depends(get_db)):
    return db.query(Item).all()
```

### Pydantic v2 모델
```python
from pydantic import BaseModel, ConfigDict, Field

class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., gt=0)

class ItemResponse(ItemCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)
```

### pytest 픽스처
```python
import pytest

@pytest.fixture
def sample_data():
    """Reusable test data."""
    return {"name": "Test", "price": 10.0}

@pytest.fixture
def db_session():
    session = TestSession()
    yield session
    session.rollback()
```

## TypeScript 패턴

### React 컴포넌트 구조
```typescript
import { type ReactNode, useState, useCallback } from 'react';

interface Props {
  title: string;
  children?: ReactNode;
  onSubmit: (data: FormData) => void;
}

export function MyComponent({ title, children, onSubmit }: Props) {
  const [state, setState] = useState<string>('');

  const handleSubmit = useCallback(() => {
    onSubmit({ value: state });
  }, [state, onSubmit]);

  return (
    <div>
      <h1>{title}</h1>
      <button onClick={handleSubmit}>제출</button>
      {children}
    </div>
  );
}
```

### 커스텀 훅 (AbortController 포함)
```typescript
import { useState, useEffect } from 'react';

function useApi<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();

    fetch(url, { signal: controller.signal })
      .then(res => res.json())
      .then(setData)
      .catch(err => {
        if (err.name !== 'AbortError') setError(err);
      })
      .finally(() => setLoading(false));

    return () => controller.abort();
  }, [url]);

  return { data, loading, error };
}
```

### TanStack Query
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function useItems() {
  return useQuery({
    queryKey: ['items'],
    queryFn: () => fetch('/api/v1/items').then(res => res.json()),
    staleTime: 5 * 60 * 1000,
  });
}

function useCreateItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ItemCreate) =>
      fetch('/api/v1/items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      }).then(res => res.json()),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['items'] });
    },
  });
}
```

### Zod 유효성 검사
```typescript
import { z } from 'zod';

const itemSchema = z.object({
  name: z.string().min(1).max(100),
  price: z.number().positive(),
  category: z.enum(['electronics', 'clothing', 'food']),
  tags: z.array(z.string()).optional(),
});

type Item = z.infer<typeof itemSchema>;

// Form 유효성 검사에 활용
function validateForm(data: unknown): Item {
  return itemSchema.parse(data);
}
```

### Error Boundary
```typescript
import { Component, type ErrorInfo, type ReactNode } from 'react';

interface Props {
  fallback: ReactNode;
  children: ReactNode;
}

interface State {
  hasError: boolean;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('ErrorBoundary caught:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}
```

### Express 미들웨어
```typescript
import { Request, Response, NextFunction } from 'express';

const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: '인증되지 않음' });
  }
  // 토큰 검증...
  next();
};
```

## 에러 처리

### Python
```python
class AppError(Exception):
    def __init__(self, message: str, code: int = 400):
        self.message = message
        self.code = code

@app.exception_handler(AppError)
async def app_error_handler(request, exc: AppError):
    return JSONResponse(
        status_code=exc.code,
        content={"error": exc.message}
    )
```

### TypeScript
```typescript
class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 400
  ) {
    super(message);
  }
}

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message });
  }
  res.status(500).json({ error: '내부 서버 오류' });
});
```

## 환경 설정

### Python (pydantic-settings)
```python
from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    debug: bool = False

    model_config = ConfigDict(env_file=".env")

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

### TypeScript
```typescript
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  SECRET_KEY: z.string().min(32),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});

export const env = envSchema.parse(process.env);
```

## 로깅

### Python
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

logger.info("서버 시작", extra={"port": 8000})
```

### TypeScript (pino)
```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  }
});

logger.info({ port: 3000 }, '서버 시작');
```
