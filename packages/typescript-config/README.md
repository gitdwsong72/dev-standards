# @company/typescript-config

Company TypeScript configuration.

Base(Node.js/범용) 설정과 React 확장 설정을 제공합니다.

## 설치

```bash
pnpm add -D @company/typescript-config typescript
```

## 사용법

### React 프로젝트

```json
// tsconfig.json
{
  "extends": "@company/typescript-config/react"
}
```

### Node.js / 범용 프로젝트

```json
// tsconfig.json
{
  "extends": "@company/typescript-config/base"
}
```

### 경로 별칭 커스터마이징

React 설정에는 기본 경로 별칭이 포함되어 있습니다:

```json
{
  "extends": "@company/typescript-config/react",
  "compilerOptions": {
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["src/shared/*"],
      "@domains/*": ["src/domains/*"]
    }
  }
}
```

## 설정 내용

### Base (`@company/typescript-config/base`)

| 옵션 | 값 | 설명 |
|------|-----|------|
| `target` | `ES2022` | 빌드 대상 |
| `module` | `ESNext` | 모듈 시스템 |
| `moduleResolution` | `bundler` | 번들러 모듈 해석 |
| `strict` | `true` | 엄격 모드 |
| `strictNullChecks` | `true` | null 체크 |
| `noUnusedLocals` | `true` | 미사용 변수 에러 |
| `noUnusedParameters` | `true` | 미사용 파라미터 에러 |
| `verbatimModuleSyntax` | `true` | 명시적 import 구문 |

### React (`@company/typescript-config/react`)

Base 설정을 확장하며 추가:

| 옵션 | 값 | 설명 |
|------|-----|------|
| `lib` | `ES2022, DOM, DOM.Iterable` | DOM API 포함 |
| `jsx` | `react-jsx` | React JSX 변환 |
| `noEmit` | `true` | Vite가 빌드 담당 |
| `paths` | `@/*, @shared/*, @domains/*` | 경로 별칭 |

## License

MIT
