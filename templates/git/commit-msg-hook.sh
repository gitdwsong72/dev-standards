#!/bin/sh
#
# commit-msg hook: commitlint으로 커밋 메시지 검증
#
# 이 스크립트는 husky를 통해 자동으로 설정됩니다.
# 수동 설정이 필요한 경우:
#   cp commit-msg-hook.sh .husky/commit-msg
#   chmod +x .husky/commit-msg

npx --no -- commitlint --edit "$1"
