# Changelog - @company/typescript-config

All notable changes to this package will be documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

---

## [1.0.0] - 2024-01-01

### Added

- 초기 TypeScript 설정
- **Base 설정 (`base.json`)**
  - `target`: ES2022
  - `module`: ESNext
  - `moduleResolution`: bundler
  - `strict`: true (엄격 모드 활성화)
  - `strictNullChecks`: true
  - `noImplicitAny`: true
  - `noImplicitReturns`: true
  - `noUnusedLocals`: true
  - `noUnusedParameters`: true
  - `noFallthroughCasesInSwitch`: true
  - `verbatimModuleSyntax`: true
  - `declaration`, `declarationMap`, `sourceMap` 활성화
- **React 설정 (`react.json`)**
  - Base 설정 상속
  - `lib`: ES2022 + DOM + DOM.Iterable
  - `jsx`: react-jsx
  - `noEmit`: true (Vite 빌드 위임)
  - 경로 별칭: `@/*`, `@shared/*`, `@domains/*`
