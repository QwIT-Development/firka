#!/usr/bin/env bash
set -euo pipefail

# Build firka and/or firka_wear with version from pubspec + short git SHA.
# Usage: ./build.sh [firka|firka_wear|all]
# Default (no args) builds both.

ROOT="$(cd "$(dirname "$0")" && pwd)"
SHA=$(git -C "$ROOT" rev-parse --short HEAD)

build_app() {
  local APP="$1"
  local PUBSPEC="$ROOT/$APP/pubspec.yaml"
  if [[ ! -f "$PUBSPEC" ]]; then
    echo "Not found: $PUBSPEC" >&2
    return 1
  fi

  local VERSION_LINE BUILD_NUMBER BASE_VERSION BUILD_NAME
  VERSION_LINE=$(grep -E '^\s*version:\s*' "$PUBSPEC" | head -1)
  BASE_VERSION=$(echo "$VERSION_LINE" | sed -E 's/^[[:space:]]*version:[[:space:]]*([^+]+).*/\1/' | tr -d ' ')
  BUILD_NUMBER=""
  if [[ "$VERSION_LINE" == *+* ]]; then
    BUILD_NUMBER=$(echo "$VERSION_LINE" | sed -E 's/^[[:space:]]*version:[[:space:]]*[^+]+\+([0-9]+).*/\1/')
  fi
  BUILD_NAME="${BASE_VERSION}-${SHA}"

  echo "Building $APP: version $BUILD_NAME (build number: ${BUILD_NUMBER:-none})"
  cd "$ROOT/$APP"

  local FLUTTER_ARGS=(build appbundle --build-name="$BUILD_NAME" --verbose)
  [[ -n "${BUILD_NUMBER:-}" ]] && FLUTTER_ARGS+=(--build-number="$BUILD_NUMBER")

  flutter "${FLUTTER_ARGS[@]}"
}

case "${1:-all}" in
  firka)      build_app firka ;;
  firka_wear) build_app firka_wear ;;
  all)        build_app firka && build_app firka_wear ;;
  *)
    echo "Usage: $0 [firka|firka_wear|all]" >&2
    exit 1
    ;;
esac
