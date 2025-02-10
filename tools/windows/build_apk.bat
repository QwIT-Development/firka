@echo off

cd firka
flutter clean
flutter pub get

flutter gen-l10n --template-arb-file app_hu.arb

flutter build apk --release --tree-shake-icons --split-per-abi --target-platform android-arm,android-arm64,android-x64
