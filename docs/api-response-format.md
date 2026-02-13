# API 응답 포맷 표준

모든 API 엔드포인트는 일관된 응답 형식을 사용합니다.

## 1. 기본 구조

### 성공 응답

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_abc123"
  }
}
```

### 에러 응답

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_abc123"
  }
}
```

## 2. 페이지네이션

리스트 조회 API는 다음 페이지네이션 구조를 사용합니다:

```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "total": 100,
      "page": 1,
      "page_size": 20,
      "total_pages": 5
    }
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_abc123"
  }
}
```

### 쿼리 파라미터

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `page` | int | 1 | 페이지 번호 (1부터 시작) |
| `page_size` | int | 20 | 페이지 크기 (최대 100) |

## 3. 에러 코드 표준

| 코드 | HTTP Status | 설명 |
|------|-------------|------|
| `VALIDATION_ERROR` | 400 | 입력 검증 실패 |
| `UNAUTHORIZED` | 401 | 인증 실패 |
| `FORBIDDEN` | 403 | 권한 없음 |
| `NOT_FOUND` | 404 | 리소스 없음 |
| `CONFLICT` | 409 | 리소스 충돌 (중복 등) |
| `INTERNAL_ERROR` | 500 | 서버 내부 오류 |

### 에러 상세 (details)

`details` 필드는 선택적이며, 필드별 검증 오류를 전달할 때 사용합니다:

```json
{
  "details": [
    { "field": "email", "message": "유효하지 않은 이메일 형식입니다" },
    { "field": "password", "message": "최소 8자 이상이어야 합니다" }
  ]
}
```

## 4. 사용 예시

### FastAPI 엔드포인트

```python
from app.core.response_schemas import SuccessResponse, ErrorResponse, PaginatedData
from app.core.response_utils import success_response, error_response

# 단일 조회
@router.get("/users/{user_id}")
async def get_user(user_id: int):
    user = await user_repository.find_by_id(user_id)
    if not user:
        return error_response("NOT_FOUND", "User not found", status_code=404)
    return success_response(user)

# 목록 조회 (페이지네이션)
@router.get("/users")
async def list_users(page: int = 1, page_size: int = 20):
    items, total = await user_repository.find_all(page, page_size)
    return success_response(
        PaginatedData(
            items=items,
            pagination=PaginationInfo(
                total=total,
                page=page,
                page_size=page_size,
                total_pages=(total + page_size - 1) // page_size,
            ),
        )
    )

# 생성
@router.post("/users", status_code=201)
async def create_user(data: CreateUserRequest):
    user = await user_service.create(data)
    return success_response(user, status_code=201)

# 에러 처리
@router.put("/users/{user_id}")
async def update_user(user_id: int, data: UpdateUserRequest):
    try:
        user = await user_service.update(user_id, data)
        return success_response(user)
    except ValueError as e:
        return error_response("VALIDATION_ERROR", str(e))
```

## 5. 템플릿 파일

프로젝트 생성 시 자동으로 다음 파일이 포함됩니다:

- `app/core/response_schemas.py` - Pydantic 스키마 정의
- `app/core/response_utils.py` - 헬퍼 함수

`templates/backend/` 디렉토리에서 원본을 확인할 수 있습니다.
