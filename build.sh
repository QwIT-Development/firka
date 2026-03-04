#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SHA=$(git -C "$ROOT" rev-parse --short HEAD)
COMMIT_COUNT=$(git -C "$ROOT" rev-list --count HEAD)

build_app() {
  local APP="$1"
  local PUBSPEC="$ROOT/$APP/pubspec.yaml"
  if [[ ! -f "$PUBSPEC" ]]; then
    echo "Not found: $PUBSPEC" >&2
    return 1
  fi

  local VERSION_LINE BASE_VERSION BUILD_NAME VERSION_CODE
  VERSION_LINE=$(grep -E '^\s*version:\s*' "$PUBSPEC" | head -1)
  BASE_VERSION=$(echo "$VERSION_LINE" | sed -E 's/^[[:space:]]*version:[[:space:]]*([^+]+).*/\1/' | tr -d ' ')
  BUILD_NAME="${BASE_VERSION}-${SHA}"

  VERSION_CODE=$((2000 + COMMIT_COUNT))
  [[ "$APP" == "firka_wear" ]] && VERSION_CODE=$((VERSION_CODE + 1))

  echo "Building $APP: version $BUILD_NAME (version code: $VERSION_CODE)"
  cd "$ROOT/$APP"

  flutter pub get
  dart run scripts/codegen.dart

  flutter build appbundle --build-name="$BUILD_NAME" --build-number="$VERSION_CODE" --verbose
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
