/**
 * LoginForm - 로그인 폼 구현 예제
 *
 * react-hook-form + Zod + useFormValidation + FormField 조합 예시입니다.
 * 프로젝트에 맞게 수정하여 사용하세요.
 */

import { z } from 'zod';
import { useFormValidation } from '@/hooks/useFormValidation';
import { FormField } from '@/components/FormField';

// ─── Zod 스키마 ────────────────────────────────────────────

const loginSchema = z.object({
  email: z
    .string()
    .min(1, '이메일을 입력해주세요')
    .email('유효한 이메일 형식이 아닙니다'),
  password: z
    .string()
    .min(8, '비밀번호는 최소 8자 이상이어야 합니다'),
});

type LoginFormData = z.infer<typeof loginSchema>;

// ─── 컴포넌트 ──────────────────────────────────────────────

export function LoginForm() {
  const { register, handleSubmit, errors, isSubmitting, rootError } =
    useFormValidation<LoginFormData>({
      schema: loginSchema,
      onSubmit: async (data) => {
        // TODO: 실제 API 호출로 교체
        // await authApi.login(data);
        console.log('login:', data);
      },
    });

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h2>로그인</h2>

      {rootError && (
        <div className="error-banner" role="alert">
          {rootError}
        </div>
      )}

      <FormField label="이메일" error={errors.email?.message} required>
        <input
          {...register('email')}
          type="email"
          placeholder="이메일을 입력하세요"
          autoComplete="email"
        />
      </FormField>

      <FormField label="비밀번호" error={errors.password?.message} required>
        <input
          {...register('password')}
          type="password"
          placeholder="비밀번호를 입력하세요"
          autoComplete="current-password"
        />
      </FormField>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? '로그인 중...' : '로그인'}
      </button>
    </form>
  );
}
