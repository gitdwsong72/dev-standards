/**
 * React Context 인증 상태 관리.
 *
 * 앱 전체에서 인증 상태를 공유하기 위한 Context Provider입니다.
 * 자세한 내용: docs/auth-patterns.md
 *
 * 사용 예시:
 *   // App.tsx
 *   import { AuthProvider } from '@/auth/AuthContext';
 *
 *   function App() {
 *     return (
 *       <AuthProvider>
 *         <Router />
 *       </AuthProvider>
 *     );
 *   }
 */

import {
  createContext,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

// ============================================================
// Types
// ============================================================

export interface User {
  id: string;
  email: string;
  role: string;
}

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

export interface AuthContextValue {
  /** 현재 로그인한 사용자 (없으면 null) */
  user: User | null;
  /** 인증 상태 로딩 중 여부 */
  isLoading: boolean;
  /** 로그인 여부 */
  isAuthenticated: boolean;
  /** Access Token (메모리 저장) */
  accessToken: string | null;
  /** 로그인 */
  login: (email: string, password: string) => Promise<void>;
  /** 로그아웃 */
  logout: () => Promise<void>;
  /** 토큰 갱신 */
  refreshAccessToken: () => Promise<string | null>;
}

// ============================================================
// Context
// ============================================================

export const AuthContext = createContext<AuthContextValue | null>(null);

// ============================================================
// API 설정 (프로젝트에 맞게 수정)
// ============================================================

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api';

// ============================================================
// Provider
// ============================================================

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isAuthenticated = user !== null;

  // ----------------------------------------------------------
  // 토큰 갱신
  // ----------------------------------------------------------
  const refreshAccessToken = useCallback(async (): Promise<string | null> => {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
        method: 'POST',
        credentials: 'include', // httpOnly Cookie로 Refresh Token 전송
      });

      if (!response.ok) {
        setUser(null);
        setAccessToken(null);
        return null;
      }

      const result = await response.json();
      const newToken: string = result.data.access_token;
      setAccessToken(newToken);
      return newToken;
    } catch {
      setUser(null);
      setAccessToken(null);
      return null;
    }
  }, []);

  // ----------------------------------------------------------
  // 현재 사용자 조회
  // ----------------------------------------------------------
  const fetchCurrentUser = useCallback(
    async (token: string): Promise<User | null> => {
      try {
        const response = await fetch(`${API_BASE_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${token}` },
        });

        if (!response.ok) return null;

        const result = await response.json();
        return result.data as User;
      } catch {
        return null;
      }
    },
    [],
  );

  // ----------------------------------------------------------
  // 로그인
  // ----------------------------------------------------------
  const login = useCallback(
    async (email: string, password: string): Promise<void> => {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        const result = await response.json();
        throw new Error(result.error?.message ?? 'Login failed');
      }

      const result = await response.json();
      const tokens: AuthTokens = result.data;

      setAccessToken(tokens.access_token);

      const currentUser = await fetchCurrentUser(tokens.access_token);
      setUser(currentUser);
    },
    [fetchCurrentUser],
  );

  // ----------------------------------------------------------
  // 로그아웃
  // ----------------------------------------------------------
  const logout = useCallback(async (): Promise<void> => {
    try {
      if (accessToken) {
        await fetch(`${API_BASE_URL}/auth/logout`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${accessToken}` },
          credentials: 'include',
        });
      }
    } finally {
      setUser(null);
      setAccessToken(null);
    }
  }, [accessToken]);

  // ----------------------------------------------------------
  // 앱 시작 시 세션 복원
  // ----------------------------------------------------------
  useEffect(() => {
    const initAuth = async () => {
      setIsLoading(true);
      try {
        const token = await refreshAccessToken();
        if (token) {
          const currentUser = await fetchCurrentUser(token);
          setUser(currentUser);
        }
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, [refreshAccessToken, fetchCurrentUser]);

  // ----------------------------------------------------------
  // Context Value
  // ----------------------------------------------------------
  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isLoading,
      isAuthenticated,
      accessToken,
      login,
      logout,
      refreshAccessToken,
    }),
    [user, isLoading, isAuthenticated, accessToken, login, logout, refreshAccessToken],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
