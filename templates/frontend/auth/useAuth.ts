/**
 * 인증 커스텀 Hook.
 *
 * AuthContext에서 인증 상태와 액션을 가져오는 Hook입니다.
 * 자세한 내용: docs/auth-patterns.md
 *
 * 사용 예시:
 *   import { useAuth } from '@/auth/useAuth';
 *
 *   function LoginPage() {
 *     const { login, isLoading } = useAuth();
 *
 *     const handleSubmit = async (email: string, password: string) => {
 *       try {
 *         await login(email, password);
 *       } catch (error) {
 *         // 에러 처리
 *       }
 *     };
 *   }
 */

import { useContext } from 'react';

import { AuthContext, type AuthContextValue } from './AuthContext';

/**
 * 인증 상태와 액션을 반환하는 Hook.
 *
 * 반드시 AuthProvider 내부에서 사용해야 합니다.
 *
 * @returns AuthContextValue
 * @throws AuthProvider 외부에서 호출 시 에러
 */
export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);

  if (context === null) {
    throw new Error('useAuth must be used within an AuthProvider');
  }

  return context;
}
