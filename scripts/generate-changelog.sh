#!/usr/bin/env bash
# generate-changelog.sh - CHANGELOG.md를 로컬에서 생성하는 스크립트
#
# Usage:
#   ./scripts/generate-changelog.sh              # 전체 changelog 생성
#   ./scripts/generate-changelog.sh --tag v1.2.0 # 특정 태그까지 생성
#   ./scripts/generate-changelog.sh --unreleased  # 미릴리스 변경사항만 출력
#   ./scripts/generate-changelog.sh --dry-run     # 미리보기 (파일 변경 없음)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$ROOT_DIR/cliff.toml"
OUTPUT="$ROOT_DIR/CHANGELOG.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Defaults
TAG=""
UNRELEASED=false
DRY_RUN=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --tag VERSION    Generate changelog up to VERSION (e.g., v1.2.0)"
    echo "  --unreleased     Show only unreleased changes (stdout only)"
    echo "  --dry-run        Preview changelog without writing to file"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Generate full CHANGELOG.md"
    echo "  $0 --tag v1.2.0           # Generate up to v1.2.0"
    echo "  $0 --unreleased           # Preview unreleased changes"
    echo "  $0 --dry-run              # Preview full changelog"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            TAG="$2"
            shift 2
            ;;
        --unreleased)
            UNRELEASED=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Check git-cliff is installed
if ! command -v git-cliff &>/dev/null; then
    echo -e "${RED}Error: git-cliff is not installed${NC}"
    echo ""
    echo "Install with one of:"
    echo "  brew install git-cliff          # macOS (Homebrew)"
    echo "  cargo install git-cliff         # Rust (cargo)"
    echo "  npm install -g git-cliff        # npm"
    echo ""
    echo "See: https://git-cliff.org/docs/installation"
    exit 1
fi

# Check config exists
if [[ ! -f "$CONFIG" ]]; then
    echo -e "${RED}Error: cliff.toml not found at $CONFIG${NC}"
    exit 1
fi

cd "$ROOT_DIR"

# Build arguments
ARGS=(--config "$CONFIG")

if [[ -n "$TAG" ]]; then
    ARGS+=(--tag "$TAG")
fi

if [[ "$UNRELEASED" == true ]]; then
    ARGS+=(--unreleased)
    echo -e "${YELLOW}Unreleased changes:${NC}"
    echo "---"
    git-cliff "${ARGS[@]}"
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Preview (dry-run):${NC}"
    echo "---"
    git-cliff "${ARGS[@]}"
    exit 0
fi

# Generate changelog
ARGS+=(--output "$OUTPUT")
git-cliff "${ARGS[@]}"

echo -e "${GREEN}CHANGELOG.md generated successfully${NC}"
echo "  File: $OUTPUT"

# Show summary
SECTIONS=$(grep -c "^### " "$OUTPUT" 2>/dev/null || echo "0")
ENTRIES=$(grep -c "^    - " "$OUTPUT" 2>/dev/null || echo "0")
echo "  Sections: $SECTIONS"
echo "  Entries: $ENTRIES"
