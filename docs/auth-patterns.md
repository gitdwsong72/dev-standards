# 인증/인가 패턴 표준

JWT 기반 인증/인가 패턴 가이드입니다.

## 1. JWT 토큰 구조

### Access Token

짧은 수명의 토큰으로 API 요청 인증에 사용합니다.

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user_123",
    "email": "user@example.com",
    "role": "admin",
    "exp": 1700000000,
    "iat": 1699998200,
    "jti": "unique-token-id"
  }
}
```

| 필드 | 설명 | 비고 |
|------|------|------|
| `sub` | 사용자 고유 ID | 필수 |
| `email` | 이메일 | 선택 |
| `role` | 사용자 역할 | 권한 검사에 사용 |
| `exp` | 만료 시간 | 필수 (30분 권장) |
| `iat` | 발급 시간 | 필수 |
| `jti` | 토큰 고유 ID | 토큰 무효화에 사용 |

### Refresh Token

Access Token 갱신에 사용하는 장수명 토큰입니다.

```json
{
  "payload": {
    "sub": "user_123",
    "exp": 1700604800,
    "iat": 1699998200,
    "jti": "refresh-token-id",
    "type": "refresh"
  }
}
```

- 만료 시간: 7일 권장
- DB에 저장하여 무효화 가능하게 관리
- Access Token과 별도의 시크릿 키 사용 권장

## 2. 인증 플로우

### 로그인 플로우

```
Client                    Server
  |                         |
  |  POST /auth/login       |
  |  { email, password }    |
  |------------------------>|
  |                         | 1. 이메일로 사용자 조회
  |                         | 2. 비밀번호 해시 검증
  |                         | 3. Access + Refresh Token 생성
  |  { access_token,        |
  |    refresh_token,       |
  |    token_type }         |
  |<------------------------|
  |                         |
```

### 토큰 갱신 플로우

```
Client                    Server
  |                         |
  |  POST /auth/refresh     |
  |  { refresh_token }      |
  |------------------------>|
  |                         | 1. Refresh Token 검증
  |                         | 2. 새 Access Token 발급
  |  { access_token,        |
  |    token_type }         |
  |<------------------------|
  |                         |
```

### API 요청 인증

```
Client                    Server
  |                         |
  |  GET /api/resource      |
  |  Authorization: Bearer  |
  |  <access_token>         |
  |------------------------>|
  |                         | 1. Bearer 토큰 추출
  |                         | 2. JWT 디코딩/검증
  |                         | 3. 사용자 권한 확인
  |  200 OK / 401 / 403    |
  |<------------------------|
  |                         |
```

## 3. 보안 권장사항

### 비밀번호

- **bcrypt** 사용 (cost factor 12 이상)
- 평문 비밀번호 절대 저장 금지
- 비밀번호 최소 요구사항: 8자 이상

### 토큰 관리

| 항목 | 권장사항 |
|------|----------|
| Access Token 수명 | 30분 |
| Refresh Token 수명 | 7일 |
| 시크릿 키 길이 | 256비트 이상 |
| 알고리즘 | HS256 (단일 서버), RS256 (마이크로서비스) |
| 시크릿 키 저장 | 환경변수 (.env), 절대 코드에 하드코딩 금지 |

### Frontend 토큰 저장

| 저장 방식 | 보안 수준 | 비고 |
|-----------|----------|------|
| httpOnly Cookie | 높음 | CSRF 방어 필요, 권장 |
| 메모리 (변수) | 높음 | 새로고침 시 초기화 |
| localStorage | 낮음 | XSS에 취약, 비권장 |

**권장 방식**: Access Token은 메모리에, Refresh Token은 httpOnly Cookie에 저장

### CORS 설정

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-domain.com"],  # 특정 도메인만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 역할 기반 접근 제어 (RBAC)

```python
# 역할 정의
class UserRole(str, Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    USER = "user"

# 역할별 권한 매핑
ROLE_PERMISSIONS = {
    UserRole.ADMIN: {"read", "write", "delete", "manage_users"},
    UserRole.MANAGER: {"read", "write", "delete"},
    UserRole.USER: {"read", "write"},
}
```

## 4. API 엔드포인트 표준

| 엔드포인트 | 메서드 | 설명 | 인증 |
|------------|--------|------|------|
| `/auth/login` | POST | 로그인 | 불필요 |
| `/auth/refresh` | POST | 토큰 갱신 | Refresh Token |
| `/auth/logout` | POST | 로그아웃 | Access Token |
| `/auth/me` | GET | 현재 사용자 정보 | Access Token |

### 응답 형식

기존 API 응답 포맷 표준(`docs/api-response-format.md`)을 따릅니다.

```json
// POST /auth/login 성공
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "token_type": "bearer"
  },
  "meta": { "timestamp": "...", "request_id": "..." }
}

// POST /auth/login 실패
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid email or password"
  },
  "meta": { "timestamp": "...", "request_id": "..." }
}
```

## 5. 템플릿 파일

프로젝트 생성 시 다음 파일이 포함됩니다:

### Backend
- `app/core/auth/jwt_handler.py` - JWT 토큰 생성/검증, 비밀번호 해싱
- `app/core/auth/dependencies.py` - FastAPI 인증 의존성 (Depends)

### Frontend
- `src/auth/AuthContext.tsx` - React Context 인증 상태 관리
- `src/auth/useAuth.ts` - 인증 커스텀 Hook
- `src/auth/ProtectedRoute.tsx` - 보호된 라우트 컴포넌트

`templates/backend/auth/` 및 `templates/frontend/auth/` 디렉토리에서 원본을 확인할 수 있습니다.
