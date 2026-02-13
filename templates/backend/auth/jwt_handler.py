"""JWT 토큰 생성/검증 및 비밀번호 해싱.

인증에 필요한 핵심 유틸리티를 제공합니다.
자세한 내용: docs/auth-patterns.md

의존성:
    pip install pyjwt[crypto] passlib[bcrypt]
    또는
    uv pip install pyjwt[crypto] passlib[bcrypt]
"""

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any, Optional

import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings


class AuthSettings(BaseSettings):
    """인증 관련 설정.

    환경변수에서 자동으로 값을 로드합니다.
    .env 파일 예시:
        SECRET_KEY=your-secret-key-at-least-256-bits
        REFRESH_SECRET_KEY=your-refresh-secret-key
        ACCESS_TOKEN_EXPIRE_MINUTES=30
        REFRESH_TOKEN_EXPIRE_DAYS=7
    """

    SECRET_KEY: str = Field(description="Access Token 서명 시크릿 키 (256비트 이상)")
    REFRESH_SECRET_KEY: str = Field(description="Refresh Token 서명 시크릿 키")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30)
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(default=7)
    ALGORITHM: str = Field(default="HS256")

    model_config = {"env_prefix": "", "env_file": ".env"}


class TokenPayload(BaseModel):
    """디코딩된 JWT 토큰 페이로드."""

    sub: str
    exp: datetime
    iat: datetime
    jti: str
    role: Optional[str] = None
    token_type: str = "access"


class TokenResponse(BaseModel):
    """토큰 응답 스키마."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# 비밀번호 해싱 컨텍스트 (bcrypt, cost factor 12)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)


def hash_password(password: str) -> str:
    """비밀번호를 bcrypt로 해싱합니다.

    Args:
        password: 평문 비밀번호

    Returns:
        해싱된 비밀번호 문자열
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """평문 비밀번호와 해시를 비교합니다.

    Args:
        plain_password: 평문 비밀번호
        hashed_password: 해싱된 비밀번호

    Returns:
        일치 여부
    """
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(
    settings: AuthSettings,
    subject: str,
    role: Optional[str] = None,
    extra_claims: Optional[dict[str, Any]] = None,
) -> str:
    """Access Token을 생성합니다.

    Args:
        settings: 인증 설정
        subject: 사용자 고유 ID (sub 클레임)
        role: 사용자 역할
        extra_claims: 추가 클레임

    Returns:
        JWT 문자열
    """
    now = datetime.now(UTC)
    expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    payload: dict[str, Any] = {
        "sub": subject,
        "exp": expire,
        "iat": now,
        "jti": str(uuid.uuid4()),
        "type": "access",
    }

    if role:
        payload["role"] = role
    if extra_claims:
        payload.update(extra_claims)

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(
    settings: AuthSettings,
    subject: str,
) -> str:
    """Refresh Token을 생성합니다.

    Args:
        settings: 인증 설정
        subject: 사용자 고유 ID (sub 클레임)

    Returns:
        JWT 문자열
    """
    now = datetime.now(UTC)
    expire = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    payload: dict[str, Any] = {
        "sub": subject,
        "exp": expire,
        "iat": now,
        "jti": str(uuid.uuid4()),
        "type": "refresh",
    }

    return jwt.encode(
        payload, settings.REFRESH_SECRET_KEY, algorithm=settings.ALGORITHM
    )


def create_tokens(
    settings: AuthSettings,
    subject: str,
    role: Optional[str] = None,
) -> TokenResponse:
    """Access Token과 Refresh Token을 함께 생성합니다.

    Args:
        settings: 인증 설정
        subject: 사용자 고유 ID
        role: 사용자 역할

    Returns:
        TokenResponse (access_token, refresh_token, token_type)
    """
    return TokenResponse(
        access_token=create_access_token(settings, subject, role),
        refresh_token=create_refresh_token(settings, subject),
    )


def decode_access_token(settings: AuthSettings, token: str) -> TokenPayload:
    """Access Token을 디코딩하고 검증합니다.

    Args:
        settings: 인증 설정
        token: JWT 문자열

    Returns:
        TokenPayload

    Raises:
        jwt.ExpiredSignatureError: 토큰 만료
        jwt.InvalidTokenError: 유효하지 않은 토큰
    """
    payload = jwt.decode(
        token,
        settings.SECRET_KEY,
        algorithms=[settings.ALGORITHM],
    )
    return TokenPayload(**payload, token_type="access")


def decode_refresh_token(settings: AuthSettings, token: str) -> TokenPayload:
    """Refresh Token을 디코딩하고 검증합니다.

    Args:
        settings: 인증 설정
        token: JWT 문자열

    Returns:
        TokenPayload

    Raises:
        jwt.ExpiredSignatureError: 토큰 만료
        jwt.InvalidTokenError: 유효하지 않은 토큰
    """
    payload = jwt.decode(
        token,
        settings.REFRESH_SECRET_KEY,
        algorithms=[settings.ALGORITHM],
    )
    return TokenPayload(**payload, token_type="refresh")
