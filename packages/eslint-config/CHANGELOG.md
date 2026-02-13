# Changelog - @company/eslint-config

All notable changes to this package will be documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

---

## [1.0.0] - 2024-01-01

### Added

- ESLint Flat Config 기반 초기 설정
- **Base 설정 (`index.js`)**
  - `@eslint/js` recommended 규칙
  - `typescript-eslint` recommended 규칙
  - `eslint-plugin-import-x` import 정렬 및 순환 참조 감지
  - `eslint-plugin-security` 보안 규칙
  - `prefer-const`, `no-var`, `eqeqeq` 등 일반 규칙
  - `no-console` warn (allow: warn, error)
- **React 설정 (`react.js`)**
  - Base 설정 상속
  - `eslint-plugin-react` JSX 규칙
  - `eslint-plugin-react-hooks` Hook 규칙
  - React 보안 규칙 (`jsx-no-script-url`, `jsx-no-target-blank`)
- Peer dependencies: `eslint` >= 9.0.0, `typescript` >= 5.0.0
- 기본 ignore 패턴: `node_modules/`, `dist/`, `build/`, `*.config.js`
