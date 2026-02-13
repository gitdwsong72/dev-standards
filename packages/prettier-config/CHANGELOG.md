# Changelog - @company/prettier-config

All notable changes to this package will be documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

---

## [1.0.0] - 2024-01-01

### Added

- 초기 Prettier 설정
  - `semi`: true (세미콜론 사용)
  - `singleQuote`: true (작은따옴표)
  - `tabWidth`: 2 (들여쓰기 2칸)
  - `trailingComma`: "all" (후행 쉼표)
  - `printWidth`: 100 (줄 너비)
  - `bracketSpacing`: true (객체 괄호 간격)
  - `arrowParens`: "always" (화살표 함수 괄호)
  - `endOfLine`: "lf" (LF 줄바꿈)
  - `useTabs`: false (스페이스 사용)
  - `quoteProps`: "as-needed"
  - `jsxSingleQuote`: false (JSX 큰따옴표)
  - `proseWrap`: "preserve"
  - `htmlWhitespaceSensitivity`: "css"
  - `embeddedLanguageFormatting`: "auto"
- Peer dependency: `prettier` >= 3.0.0
