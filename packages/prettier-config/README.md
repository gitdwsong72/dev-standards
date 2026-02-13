# @company/prettier-config

Company Prettier configuration.

팀 공통 코드 포맷팅 설정을 제공합니다.

## 설치

```bash
pnpm add -D @company/prettier-config prettier
```

## 사용법

### 방법 1: prettier.config.js

```javascript
// prettier.config.js
import config from '@company/prettier-config';
export default config;
```

### 방법 2: package.json

```json
{
  "prettier": "@company/prettier-config"
}
```

### 규칙 커스터마이징

```javascript
// prettier.config.js
import config from '@company/prettier-config';

export default {
  ...config,
  printWidth: 120,
};
```

## 설정 값

| 옵션 | 값 | 설명 |
|------|-----|------|
| `semi` | `true` | 세미콜론 사용 |
| `singleQuote` | `true` | 작은따옴표 사용 |
| `tabWidth` | `2` | 들여쓰기 2칸 |
| `trailingComma` | `"all"` | 후행 쉼표 |
| `printWidth` | `100` | 줄 너비 100자 |
| `bracketSpacing` | `true` | 객체 괄호 간격 |
| `arrowParens` | `"always"` | 화살표 함수 괄호 항상 사용 |
| `endOfLine` | `"lf"` | LF 줄바꿈 |
| `useTabs` | `false` | 스페이스 사용 |

## Peer Dependencies

- `prettier` >= 3.0.0

## License

MIT
