"""FastAPI 인증 의존성 (Depends).

라우터에서 인증/인가를 적용하기 위한 의존성 함수들입니다.
자세한 내용: docs/auth-patterns.md

사용 예시:
    @router.get("/users/me")
    async def get_me(current_user: User = Depends(get_current_user)):
        return success_response(current_user)

    @router.delete("/users/{user_id}")
    async def delete_user(
        user_id: int,
        current_user: User = Depends(require_role("admin")),
    ):
        ...
"""

from enum import Enum
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .jwt_handler import AuthSettings, TokenPayload, decode_access_token

# Bearer 토큰 스키마
bearer_scheme = HTTPBearer(auto_error=False)


class UserRole(str, Enum):
    """사용자 역할."""

    ADMIN = "admin"
    MANAGER = "manager"
    USER = "user"


# 역할별 권한 매핑
ROLE_PERMISSIONS: dict[UserRole, set[str]] = {
    UserRole.ADMIN: {"read", "write", "delete", "manage_users"},
    UserRole.MANAGER: {"read", "write", "delete"},
    UserRole.USER: {"read", "write"},
}


def get_auth_settings() -> AuthSettings:
    """인증 설정을 반환합니다.

    실제 프로젝트에서는 앱 시작 시 생성된 설정 인스턴스를 반환하도록 수정하세요.
    """
    return AuthSettings()


async def get_token_payload(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(bearer_scheme)
    ],
    settings: Annotated[AuthSettings, Depends(get_auth_settings)],
) -> TokenPayload:
    """Authorization 헤더에서 토큰을 추출하고 검증합니다.

    Args:
        credentials: Bearer 토큰 자격 증명
        settings: 인증 설정

    Returns:
        TokenPayload: 디코딩된 토큰 페이로드

    Raises:
        HTTPException(401): 토큰 없음, 만료, 또는 유효하지 않음
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="인증 토큰이 필요합니다",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        return decode_access_token(settings, credentials.credentials)
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰이 만료되었습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="유효하지 않은 토큰입니다",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: Annotated[TokenPayload, Depends(get_token_payload)],
) -> TokenPayload:
    """현재 인증된 사용자를 반환합니다.

    실제 프로젝트에서는 token.sub로 DB에서 User 객체를 조회하여 반환하도록 수정하세요.

    Args:
        token: 검증된 토큰 페이로드

    Returns:
        TokenPayload (실제 프로젝트에서는 User 모델)

    사용 예시:
        @router.get("/me")
        async def get_me(current_user: User = Depends(get_current_user)):
            return success_response(current_user)
    """
    # TODO: DB에서 사용자 조회
    # user = await user_repository.find_by_id(token.sub)
    # if user is None:
    #     raise HTTPException(status_code=401, detail="사용자를 찾을 수 없습니다")
    # return user
    return token


def require_role(*roles: UserRole):
    """특정 역할을 가진 사용자만 접근을 허용하는 의존성을 반환합니다.

    Args:
        *roles: 허용할 역할 목록

    Returns:
        FastAPI 의존성 함수

    사용 예시:
        @router.delete("/users/{user_id}")
        async def delete_user(
            user_id: int,
            current_user: User = Depends(require_role(UserRole.ADMIN)),
        ):
            ...

        @router.put("/settings")
        async def update_settings(
            current_user: User = Depends(
                require_role(UserRole.ADMIN, UserRole.MANAGER)
            ),
        ):
            ...
    """
    allowed_roles = set(roles)

    async def _check_role(
        token: Annotated[TokenPayload, Depends(get_token_payload)],
    ) -> TokenPayload:
        if token.role is None or token.role not in {r.value for r in allowed_roles}:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="이 작업에 대한 권한이 없습니다",
            )
        # TODO: DB에서 사용자 조회 후 반환
        return token

    return _check_role


def require_permission(permission: str):
    """특정 권한이 있는 사용자만 접근을 허용하는 의존성을 반환합니다.

    ROLE_PERMISSIONS 매핑에 따라 역할별 권한을 확인합니다.

    Args:
        permission: 필요한 권한 (예: "delete", "manage_users")

    Returns:
        FastAPI 의존성 함수

    사용 예시:
        @router.delete("/posts/{post_id}")
        async def delete_post(
            post_id: int,
            current_user: User = Depends(require_permission("delete")),
        ):
            ...
    """

    async def _check_permission(
        token: Annotated[TokenPayload, Depends(get_token_payload)],
    ) -> TokenPayload:
        if token.role is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="역할이 지정되지 않았습니다",
            )

        try:
            user_role = UserRole(token.role)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="알 수 없는 역할입니다",
            )

        role_perms = ROLE_PERMISSIONS.get(user_role, set())
        if permission not in role_perms:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"'{permission}' 권한이 없습니다",
            )
        return token

    return _check_permission
