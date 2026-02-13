"""API 응답 포맷 표준 스키마.

모든 API 엔드포인트에서 사용하는 일관된 응답 구조를 정의합니다.
자세한 내용: docs/api-response-format.md
"""

from datetime import datetime
from typing import Generic, Optional, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class ResponseMeta(BaseModel):
    """응답 메타데이터."""

    timestamp: datetime = Field(default_factory=datetime.utcnow)
    request_id: Optional[str] = None


class SuccessResponse(BaseModel, Generic[T]):
    """성공 응답."""

    success: bool = Field(default=True)
    data: T
    meta: ResponseMeta = Field(default_factory=ResponseMeta)


class ErrorDetail(BaseModel):
    """에러 상세 정보 (필드별 검증 오류)."""

    field: Optional[str] = None
    message: str


class ErrorInfo(BaseModel):
    """에러 정보."""

    code: str
    message: str
    details: Optional[list[ErrorDetail]] = None


class ErrorResponse(BaseModel):
    """에러 응답."""

    success: bool = Field(default=False)
    error: ErrorInfo
    meta: ResponseMeta = Field(default_factory=ResponseMeta)


class PaginationInfo(BaseModel):
    """페이지네이션 정보."""

    total: int
    page: int
    page_size: int
    total_pages: int


class PaginatedData(BaseModel, Generic[T]):
    """페이지네이션이 포함된 목록 데이터."""

    items: list[T]
    pagination: PaginationInfo
