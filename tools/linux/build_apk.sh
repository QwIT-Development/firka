#!/bin/bash

cd firka

flutter gen-l10n --template-arb-file app_hu.arb

if [ "$1" = "main" ]; then
  if [ -f "$HOME/.flutter_path" ]; then
    sdk_path="$(cat $HOME/.flutter_path)"
    echo "Using flutter sdk from: $sdk_path"

    mkdir -p build/app/tmp
    flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=android_release --local-engine-host=host_release \
      --split-per-abi \
      --target-platform android-arm
    mv build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk build/app/tmp/
    flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=android_release_arm64 --local-engine-host=host_release \
      --split-per-abi \
      --target-platform android-arm64
    mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk build/app/tmp/
    flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=android_release_x64 --local-engine-host=host_release \
      --split-per-abi \
      --target-platform android-x64
    mv build/app/tmp/*.apk build/app/outputs/flutter-apk
  else
    echo "$HOME/.flutter_path not found!"
    exit 1
  fi
else
  flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
fi
