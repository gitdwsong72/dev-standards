/**
 * Commitlint 설정 파일
 *
 * Conventional Commits 규칙을 적용합니다.
 * https://www.conventionalcommits.org/
 *
 * 사용법:
 *   1. 이 파일을 프로젝트 루트에 복사
 *   2. pnpm add -D @commitlint/cli @commitlint/config-conventional
 *   3. husky와 함께 commit-msg hook 설정
 */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Type 제한: 허용되는 type 목록
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 새로운 기능 추가
        'fix',      // 버그 수정
        'docs',     // 문서 수정
        'style',    // 코드 포맷팅 (기능 변경 없음)
        'refactor', // 리팩토링
        'perf',     // 성능 개선
        'test',     // 테스트 추가/수정
        'chore',    // 빌드, 설정 변경
        'ci',       // CI 설정 변경
        'revert',   // 커밋 되돌리기
      ],
    ],

    // Type은 소문자
    'type-case': [2, 'always', 'lower-case'],
    // Type은 필수
    'type-empty': [2, 'never'],

    // Scope은 소문자
    'scope-case': [2, 'always', 'lower-case'],

    // Subject는 소문자로 시작
    'subject-case': [2, 'always', 'lower-case'],
    // Subject는 필수
    'subject-empty': [2, 'never'],
    // Subject는 50자 이내
    'subject-max-length': [2, 'always', 50],
    // Subject 끝에 마침표 금지
    'subject-full-stop': [2, 'never', '.'],

    // Header 전체 72자 이내
    'header-max-length': [2, 'always', 72],

    // Body는 72자마다 줄바꿈
    'body-max-line-length': [2, 'always', 72],
  },
};
