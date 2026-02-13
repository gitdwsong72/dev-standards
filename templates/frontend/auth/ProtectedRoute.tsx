/**
 * 보호된 라우트 컴포넌트.
 *
 * 인증되지 않은 사용자를 로그인 페이지로 리다이렉트하고,
 * 역할 기반 접근 제어를 지원합니다.
 * 자세한 내용: docs/auth-patterns.md
 *
 * 사용 예시:
 *   import { ProtectedRoute } from '@/auth/ProtectedRoute';
 *
 *   // 기본 (인증만 확인)
 *   <Route element={<ProtectedRoute />}>
 *     <Route path="/dashboard" element={<Dashboard />} />
 *   </Route>
 *
 *   // 역할 기반 접근 제어
 *   <Route element={<ProtectedRoute allowedRoles={['admin', 'manager']} />}>
 *     <Route path="/admin" element={<AdminPage />} />
 *   </Route>
 *
 *   // 커스텀 로딩/리다이렉트
 *   <Route element={
 *     <ProtectedRoute
 *       loginPath="/login"
 *       unauthorizedPath="/403"
 *       loadingFallback={<Spinner />}
 *     />
 *   }>
 *     <Route path="/settings" element={<Settings />} />
 *   </Route>
 */

import { type ReactNode } from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';

import { useAuth } from './useAuth';

// ============================================================
// Types
// ============================================================

interface ProtectedRouteProps {
  /** 허용할 역할 목록 (미지정 시 인증만 확인) */
  allowedRoles?: string[];
  /** 로그인 페이지 경로 (기본: "/login") */
  loginPath?: string;
  /** 권한 없음 페이지 경로 (기본: "/unauthorized") */
  unauthorizedPath?: string;
  /** 로딩 중 표시할 컴포넌트 */
  loadingFallback?: ReactNode;
  /** 자식 컴포넌트 (Outlet 대신 사용) */
  children?: ReactNode;
}

// ============================================================
// Component
// ============================================================

export function ProtectedRoute({
  allowedRoles,
  loginPath = '/login',
  unauthorizedPath = '/unauthorized',
  loadingFallback = null,
  children,
}: ProtectedRouteProps) {
  const { user, isLoading, isAuthenticated } = useAuth();
  const location = useLocation();

  // 인증 상태 로딩 중
  if (isLoading) {
    return <>{loadingFallback}</>;
  }

  // 미인증 → 로그인 페이지로 리다이렉트 (현재 위치 저장)
  if (!isAuthenticated) {
    return <Navigate to={loginPath} state={{ from: location }} replace />;
  }

  // 역할 기반 접근 제어
  if (allowedRoles && allowedRoles.length > 0) {
    const hasRequiredRole = user?.role && allowedRoles.includes(user.role);

    if (!hasRequiredRole) {
      return <Navigate to={unauthorizedPath} replace />;
    }
  }

  // 인증 + 권한 확인 완료
  return <>{children ?? <Outlet />}</>;
}
