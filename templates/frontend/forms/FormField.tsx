/**
 * FormField - 재사용 가능한 폼 필드 컴포넌트
 *
 * 레이블, 에러 메시지, 필수 표시를 포함한 일관된 폼 필드 UI를 제공합니다.
 *
 * 사용법:
 *   <FormField label="이메일" error={errors.email?.message} required>
 *     <input {...register('email')} placeholder="이메일을 입력하세요" />
 *   </FormField>
 */

import type { ReactNode } from 'react';

interface FormFieldProps {
  /** 필드 레이블 */
  label: string;
  /** 에러 메시지 (react-hook-form errors.field?.message) */
  error?: string;
  /** 필수 입력 필드 여부 */
  required?: boolean;
  /** 보조 설명 텍스트 */
  description?: string;
  /** 자식 요소 (input, select, textarea 등) */
  children: ReactNode;
  /** 추가 CSS 클래스 */
  className?: string;
}

export function FormField({
  label,
  error,
  required = false,
  description,
  children,
  className = '',
}: FormFieldProps) {
  return (
    <div className={`form-field ${error ? 'form-field--error' : ''} ${className}`}>
      <label className="form-field__label">
        {label}
        {required && <span className="form-field__required" aria-hidden="true">*</span>}
      </label>

      {description && (
        <p className="form-field__description">{description}</p>
      )}

      <div className="form-field__input">
        {children}
      </div>

      {error && (
        <p className="form-field__error" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
