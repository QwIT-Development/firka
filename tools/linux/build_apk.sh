cd firka

flutter clean
flutter pub get
flutter gen-l10n --template-arb-file app_hu.arb

COMMIT_COUNT=$(git rev-list --count HEAD)

flutter build apk \
  --release \
  --tree-shake-icons \
  --split-per-abi \
  --build-name="1.0.${COMMIT_COUNT}" \
  --build-number="${COMMIT_COUNT}"