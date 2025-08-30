#!/bin/bash
cd firka

set -e
SHORT_SHA=$(git rev-parse --short HEAD)
COMMIT_COUNT=$(git rev-list --count HEAD)
BASE_BUILD_NUMBER=$((1000 + COMMIT_COUNT))
ORIGINAL_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: *//' | sed 's/+.*//')

update_version_for_abi() {
    local build_offset=$1
    local new_build_number=$((BASE_BUILD_NUMBER + build_offset))
    local new_version="${ORIGINAL_VERSION}-${SHORT_SHA}+${new_build_number}"
    sed -i "s/^version: .*/version: ${new_version}/" pubspec.yaml
    echo "Updated version to: ${new_version}"
}

flutter gen-l10n --template-arb-file app_hu.arb

if [ "$1" = "main" ]; then
  if [ -f "$HOME/.flutter_path" ]; then
    sdk_path="$(cat $HOME/.flutter_path)"
    echo "Using flutter sdk from: $sdk_path"
    mkdir -p build/app/tmp
    
    update_version_for_abi 1000
    TRANSFORM_APK=true flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=android_release --local-engine-host=host_release \
      --split-per-abi \
      --target-platform android-arm
    mv build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk build/app/tmp/
    
    update_version_for_abi 2000
    TRANSFORM_APK=true flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=android_release_arm64 --local-engine-host=host_release \
      --split-per-abi \
      --target-platform android-arm64
    mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk build/app/tmp/
    
    update_version_for_abi 3000
    TRANSFORM_APK=true flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=android_release_x64 --local-engine-host=host_release \
      --split-per-abi \
      --target-platform android-x64
    
    mv build/app/tmp/*.apk build/app/outputs/flutter-apk/
    mv build/app/outputs/flutter-apk/app-x86_64-release.apk build/app/outputs/flutter-apk/ 2>/dev/null || true
    
    
  else
    echo "$HOME/.flutter_path not found!"
    exit 1
  fi
else
  update_version_for_abi 0
  TRANSFORM_APK=true flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
fi
