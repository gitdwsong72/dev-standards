/**
 * useFormValidation - 폼 검증 커스텀 Hook
 *
 * react-hook-form + Zod 기반 폼 설정과 서버 에러 처리를 통합합니다.
 *
 * 사용법:
 *   const { register, handleSubmit, errors, isSubmitting, rootError } =
 *     useFormValidation<LoginFormData>({
 *       schema: loginSchema,
 *       onSubmit: async (data) => { await authApi.login(data); },
 *     });
 */

import { useForm, type DefaultValues, type FieldValues, type Path } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import type { ZodType } from 'zod';

// API 에러 응답 타입 (docs/api-response-format.md 기준)
interface ApiErrorDetail {
  field: string;
  message: string;
}

interface ApiErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: ApiErrorDetail[];
  };
}

interface UseFormValidationOptions<T extends FieldValues> {
  /** Zod 스키마 */
  schema: ZodType<T>;
  /** 폼 제출 핸들러 (검증 통과 후 호출) */
  onSubmit: (data: T) => Promise<void>;
  /** 기본값 */
  defaultValues?: DefaultValues<T>;
}

export function useFormValidation<T extends FieldValues>({
  schema,
  onSubmit,
  defaultValues,
}: UseFormValidationOptions<T>) {
  const form = useForm<T>({
    resolver: zodResolver(schema),
    defaultValues,
  });

  const {
    register,
    handleSubmit: rhfHandleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = form;

  const handleSubmit = rhfHandleSubmit(async (data) => {
    try {
      await onSubmit(data);
    } catch (err: unknown) {
      const apiError = err as ApiErrorResponse;

      if (apiError?.error?.details) {
        apiError.error.details.forEach(({ field, message }) => {
          setError(field as Path<T>, { type: 'server', message });
        });
      } else {
        const message = apiError?.error?.message ?? '요청 처리 중 오류가 발생했습니다.';
        setError('root' as Path<T>, { type: 'server', message });
      }
    }
  });

  const rootError = errors.root?.message as string | undefined;

  return {
    register,
    handleSubmit,
    errors,
    isSubmitting,
    rootError,
    /** react-hook-form 전체 인스턴스 (고급 사용) */
    form,
  };
}
