#!/bin/bash
cd firka
set -e
SHORT_SHA=$(git rev-parse --short HEAD)
COMMIT_COUNT=$(git rev-list --count HEAD)
BASE_BUILD_NUMBER=$((1000 + COMMIT_COUNT))
ORIGINAL_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: *//' | sed 's/+.*//')

update_version_for_abi() {
    local build_offset=$1
    local target_dir=$2
    local new_build_number=$((BASE_BUILD_NUMBER + build_offset))
    local new_version="${ORIGINAL_VERSION}-${SHORT_SHA}+${new_build_number}"
    sed -i "s/^version: .*/version: ${new_version}/" "${target_dir}/pubspec.yaml"
    echo "Updated version to: ${new_version} in ${target_dir}"
}

build_abi() {
    local abi=$1
    local build_offset=$2
    local engine_name=$3
    local platform=$4
    local temp_dir="build/temp_${abi}"
    
    echo "Starting build for ${abi}..."
    
    # Create temp directory and copy project files
    mkdir -p "${temp_dir}"
    mkdir -pv build/secrets
    cp -v ../secrets/* build/secrets/ || true
    rsync -a --exclude='build/' --exclude='.dart_tool/' --exclude='.git/' . "${temp_dir}/"
    
    cd "${temp_dir}"
    
    # Update version for this ABI
    update_version_for_abi ${build_offset} "."
    
    # Generate localization files
    flutter gen-l10n --template-arb-file app_hu.arb
    
    # Build APK
    sdk_path="$(cat $HOME/.flutter_path)"
    TRANSFORM_APK=true flutter build apk --release --tree-shake-icons \
      --local-engine-src-path "$sdk_path/engine/src" \
      --local-engine=${engine_name} --local-engine-host=host_release \
      --split-per-abi \
      --target-platform ${platform}
    
    # Move built APK to main build directory
    mkdir -p "../app/outputs/flutter-apk/"
    cp build/app/outputs/flutter-apk/*.apk "../app/outputs/flutter-apk/"
    
    cd - > /dev/null
    echo "Completed build for ${abi}"
}

flutter gen-l10n --template-arb-file app_hu.arb

if [ "$1" = "main" ]; then
  if [ -f "$HOME/.flutter_path" ]; then
    sdk_path="$(cat $HOME/.flutter_path)"
    echo "Using flutter sdk from: $sdk_path"
    
    # Clean up any existing temp directories and create main build directory
    rm -rf build/temp_*
    mkdir -p build/app/outputs/flutter-apk
    
    # Start parallel builds
    build_abi "arm" 1000 "android_release" "android-arm" &
    ARM_PID=$!
    
    build_abi "arm64" 2000 "android_release_arm64" "android-arm64" &
    ARM64_PID=$!
    
    build_abi "x64" 3000 "android_release_x64" "android-x64" &
    X64_PID=$!
    
    # Wait for all builds to complete
    echo "Waiting for ARM build (PID: $ARM_PID)..."
    wait $ARM_PID
    ARM_EXIT=$?
    
    echo "Waiting for ARM64 build (PID: $ARM64_PID)..."
    wait $ARM64_PID
    ARM64_EXIT=$?
    
    echo "Waiting for X64 build (PID: $X64_PID)..."
    wait $X64_PID
    X64_EXIT=$?
    
    # Check if any builds failed
    if [ $ARM_EXIT -ne 0 ] || [ $ARM64_EXIT -ne 0 ] || [ $X64_EXIT -ne 0 ]; then
        echo "One or more builds failed!"
        echo "ARM exit code: $ARM_EXIT"
        echo "ARM64 exit code: $ARM64_EXIT"
        echo "X64 exit code: $X64_EXIT"
        exit 1
    fi
    
    rm -rf build/temp_* build/secrets

    echo "All builds completed successfully!"
    ls -la build/app/outputs/flutter-apk/
    
  else
    echo "$HOME/.flutter_path not found!"
    exit 1
  fi
else
  update_version_for_abi 0 "."
  TRANSFORM_APK=true flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
fi
