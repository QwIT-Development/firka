# Set-ExecutionPolicy RemoteSigned
# ^ this might need to be run once in an admin PowerShell

Set-Location firka

flutter clean
flutter pub get
flutter gen-l10n --template-arb-file app_hu.arb

$CommitCount = (git -C .. rev-list --count HEAD).Trim()
$BuildName = "1.0.$CommitCount"
$BuildNumber = $CommitCount

flutter build apk `
    --release `
    --tree-shake-icons `
    --split-per-abi `
    --build-name=$BuildName `
    --build-number=$BuildNumber