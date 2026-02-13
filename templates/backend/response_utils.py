"""API 응답 헬퍼 함수.

일관된 응답 포맷을 쉽게 생성하기 위한 유틸리티입니다.
자세한 내용: docs/api-response-format.md
"""

from typing import Any, Optional

from fastapi.responses import JSONResponse

from .response_schemas import (
    ErrorDetail,
    ErrorInfo,
    ErrorResponse,
    ResponseMeta,
    SuccessResponse,
)


def success_response(
    data: Any,
    status_code: int = 200,
    request_id: Optional[str] = None,
) -> JSONResponse:
    """성공 응답 생성.

    Args:
        data: 응답 데이터
        status_code: HTTP 상태 코드 (기본: 200)
        request_id: 요청 추적 ID

    Returns:
        JSONResponse with standardized success format
    """
    response = SuccessResponse(
        data=data,
        meta=ResponseMeta(request_id=request_id),
    )
    return JSONResponse(
        status_code=status_code,
        content=response.model_dump(mode="json"),
    )


def error_response(
    code: str,
    message: str,
    status_code: int = 400,
    details: Optional[list[ErrorDetail]] = None,
    request_id: Optional[str] = None,
) -> JSONResponse:
    """에러 응답 생성.

    Args:
        code: 에러 코드 (예: "VALIDATION_ERROR", "NOT_FOUND")
        message: 에러 메시지
        status_code: HTTP 상태 코드 (기본: 400)
        details: 필드별 검증 오류 목록
        request_id: 요청 추적 ID

    Returns:
        JSONResponse with standardized error format
    """
    response = ErrorResponse(
        error=ErrorInfo(code=code, message=message, details=details),
        meta=ResponseMeta(request_id=request_id),
    )
    return JSONResponse(
        status_code=status_code,
        content=response.model_dump(mode="json"),
    )
