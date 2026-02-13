# React 폼 처리 패턴

react-hook-form + Zod 기반의 폼 처리 표준 패턴입니다.

## 1. 기본 구조

### 의존성

```bash
pnpm add react-hook-form zod @hookform/resolvers
```

### 스키마 정의 (Zod)

```typescript
import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().min(1, '이메일을 입력해주세요').email('유효한 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 최소 8자 이상이어야 합니다'),
});

export type LoginFormData = z.infer<typeof loginSchema>;
```

### 기본 폼 패턴

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { loginSchema, type LoginFormData } from './schema';

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormData) => {
    await authApi.login(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit" disabled={isSubmitting}>로그인</button>
    </form>
  );
}
```

## 2. 서버 검증 통합

API 에러 응답(`docs/api-response-format.md`)의 `details` 필드를 폼 필드 에러에 매핑합니다.

### API 에러 응답 형식

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      { "field": "email", "message": "이미 등록된 이메일입니다" }
    ]
  }
}
```

### 서버 에러 → 폼 필드 매핑

```typescript
import type { UseFormSetError, FieldValues, Path } from 'react-hook-form';

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

function applyServerErrors<T extends FieldValues>(
  error: ApiErrorResponse,
  setError: UseFormSetError<T>,
) {
  if (error.error.details) {
    error.error.details.forEach(({ field, message }) => {
      setError(field as Path<T>, { type: 'server', message });
    });
  } else {
    setError('root' as Path<T>, { type: 'server', message: error.error.message });
  }
}
```

### 사용 예시

```typescript
const { setError, handleSubmit } = useForm<SignupFormData>({
  resolver: zodResolver(signupSchema),
});

const onSubmit = async (data: SignupFormData) => {
  try {
    await authApi.signup(data);
  } catch (err) {
    applyServerErrors(err as ApiErrorResponse, setError);
  }
};
```

## 3. 커스텀 Hook 패턴

`useFormValidation` hook으로 폼 설정과 서버 에러 처리를 통합합니다.

```typescript
import { useFormValidation } from '@/hooks/useFormValidation';
import { signupSchema, type SignupFormData } from './schema';

function SignupForm() {
  const { register, handleSubmit, errors, isSubmitting, rootError } =
    useFormValidation<SignupFormData>({
      schema: signupSchema,
      onSubmit: async (data) => {
        await authApi.signup(data);
        router.push('/dashboard');
      },
    });

  return (
    <form onSubmit={handleSubmit}>
      {rootError && <div className="error-banner">{rootError}</div>}
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}
      <button type="submit" disabled={isSubmitting}>가입</button>
    </form>
  );
}
```

상세 구현은 `templates/frontend/forms/useFormValidation.ts` 참조

## 4. 재사용 가능한 FormField 컴포넌트

반복되는 폼 필드 + 에러 메시지 UI를 컴포넌트로 추상화합니다.

```tsx
<FormField label="이메일" error={errors.email?.message}>
  <input {...register('email')} placeholder="이메일을 입력하세요" />
</FormField>
```

상세 구현은 `templates/frontend/forms/FormField.tsx` 참조

## 5. 복잡한 폼 패턴

### 동적 필드 배열

```typescript
import { useFieldArray } from 'react-hook-form';

const orderSchema = z.object({
  customerName: z.string().min(1, '고객명을 입력해주세요'),
  items: z.array(
    z.object({
      productName: z.string().min(1, '상품명을 입력해주세요'),
      quantity: z.number().min(1, '수량은 1 이상이어야 합니다'),
      unitPrice: z.number().min(0, '단가는 0 이상이어야 합니다'),
    })
  ).min(1, '최소 1개 이상의 상품이 필요합니다'),
});

type OrderFormData = z.infer<typeof orderSchema>;

function OrderForm() {
  const { register, control, handleSubmit, formState: { errors } } =
    useForm<OrderFormData>({
      resolver: zodResolver(orderSchema),
      defaultValues: { items: [{ productName: '', quantity: 1, unitPrice: 0 }] },
    });

  const { fields, append, remove } = useFieldArray({ control, name: 'items' });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('customerName')} />

      {fields.map((field, index) => (
        <div key={field.id}>
          <input {...register(`items.${index}.productName`)} />
          {errors.items?.[index]?.productName && (
            <span>{errors.items[index].productName.message}</span>
          )}

          <input type="number" {...register(`items.${index}.quantity`, { valueAsNumber: true })} />
          <input type="number" {...register(`items.${index}.unitPrice`, { valueAsNumber: true })} />

          <button type="button" onClick={() => remove(index)}>삭제</button>
        </div>
      ))}

      <button type="button" onClick={() => append({ productName: '', quantity: 1, unitPrice: 0 })}>
        상품 추가
      </button>
      <button type="submit">주문 생성</button>
    </form>
  );
}
```

### 조건부 필드

```typescript
const profileSchema = z.discriminatedUnion('role', [
  z.object({
    role: z.literal('employee'),
    employeeId: z.string().min(1, '사번을 입력해주세요'),
    department: z.string().min(1, '부서를 입력해주세요'),
  }),
  z.object({
    role: z.literal('external'),
    companyName: z.string().min(1, '회사명을 입력해주세요'),
    contractDate: z.string().min(1, '계약일을 입력해주세요'),
  }),
]);

type ProfileFormData = z.infer<typeof profileSchema>;

function ProfileForm() {
  const { register, watch, handleSubmit, formState: { errors } } =
    useForm<ProfileFormData>({
      resolver: zodResolver(profileSchema),
      defaultValues: { role: 'employee' },
    });

  const role = watch('role');

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <select {...register('role')}>
        <option value="employee">임직원</option>
        <option value="external">외부인</option>
      </select>

      {role === 'employee' && (
        <>
          <input {...register('employeeId')} placeholder="사번" />
          <input {...register('department')} placeholder="부서" />
        </>
      )}

      {role === 'external' && (
        <>
          <input {...register('companyName')} placeholder="회사명" />
          <input {...register('contractDate')} type="date" />
        </>
      )}

      <button type="submit">저장</button>
    </form>
  );
}
```

## 6. 파일 구조

폼 관련 코드는 도메인 디렉토리 내에서 다음 구조를 따릅니다:

```
src/domains/{domain}/
├── schemas/
│   └── {domain}Schema.ts       # Zod 스키마 + 타입 추출
├── components/
│   └── {Domain}Form.tsx         # 폼 컴포넌트
└── hooks/
    └── use{Domain}Form.ts       # 폼 로직 커스텀 훅 (필요 시)
```

## 7. 템플릿 파일

프로젝트에서 바로 사용할 수 있는 템플릿 파일:

- `templates/frontend/forms/useFormValidation.ts` - 폼 검증 커스텀 hook
- `templates/frontend/forms/FormField.tsx` - 재사용 가능한 폼 필드 컴포넌트
- `templates/frontend/forms/example-LoginForm.tsx` - 로그인 폼 구현 예제
