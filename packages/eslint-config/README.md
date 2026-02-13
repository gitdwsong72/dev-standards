# @company/eslint-config

Company ESLint configuration for TypeScript and React + TypeScript projects.

ESLint Flat Config 기반으로, Base(TypeScript) 설정과 React 확장 설정을 제공합니다.

## 설치

```bash
pnpm add -D @company/eslint-config eslint typescript
```

## 사용법

### React + TypeScript 프로젝트

```javascript
// eslint.config.js
import config from '@company/eslint-config/react';
export default config;
```

### TypeScript 프로젝트 (React 없이)

```javascript
// eslint.config.js
import config from '@company/eslint-config';
export default config;
```

### 규칙 커스터마이징

```javascript
// eslint.config.js
import config from '@company/eslint-config/react';

export default [
  ...config,
  {
    rules: {
      'no-console': 'off',
    },
  },
];
```

## 포함된 규칙

### Base (`@company/eslint-config`)

| 카테고리 | 주요 규칙 |
|----------|----------|
| TypeScript | `no-unused-vars` (error), `no-explicit-any` (warn) |
| Import | `import-x/order` (자동 정렬), `no-cycle`, `no-duplicates` |
| General | `prefer-const`, `no-var`, `eqeqeq`, `no-console` (warn) |
| Security | `no-eval`, `detect-unsafe-regex`, `detect-object-injection` |

### React (`@company/eslint-config/react`)

Base 규칙에 추가:

| 카테고리 | 주요 규칙 |
|----------|----------|
| React | `jsx-key` (error), `self-closing-comp`, `no-danger` (warn) |
| React Hooks | `rules-of-hooks` (error), `exhaustive-deps` (warn) |
| Security | `jsx-no-script-url`, `jsx-no-target-blank` |

## Peer Dependencies

- `eslint` >= 9.0.0
- `typescript` >= 5.0.0

## License

MIT
