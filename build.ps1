$ErrorActionPreference = 'Stop'

$ROOT = $PSScriptRoot
$SHA = (git -C $ROOT rev-parse --short HEAD)
$COMMIT_COUNT = [int](git -C $ROOT rev-list --count HEAD)

function Build-App {
  param([string]$App)

  $pubspec = Join-Path $ROOT $App "pubspec.yaml"
  if (-not (Test-Path $pubspec)) {
    Write-Error "Not found: $pubspec"
  }

  $versionLine = Get-Content $pubspec | Select-String -Pattern '^\s*version:\s*' | Select-Object -First 1
  if (-not $versionLine) {
    Write-Error "No version line in $pubspec"
  }
  $line = $versionLine.Line
  if ($line -match '^\s*version:\s*([^+\s]+)') {
    $baseVersion = $Matches[1].Trim()
  } else {
    Write-Error "Could not parse version from: $line"
  }

  $buildName = "${baseVersion}-${SHA}"
  $versionCode = 2000 + $COMMIT_COUNT
  if ($App -eq "firka_wear") {
    $versionCode += 1
  }

  Write-Host "Building $App : version $buildName (version code: $versionCode)"
  Push-Location (Join-Path $ROOT $App)
  try {
    flutter pub get
    dart run scripts/codegen.dart
    flutter build appbundle --build-name="$buildName" --build-number="$versionCode" --verbose
  } finally {
    Pop-Location
  }
}

$target = if ($args.Count -gt 0) { $args[0] } else { "all" }

switch ($target) {
  "firka"      { Build-App firka }
  "firka_wear" { Build-App firka_wear }
  "all"        { Build-App firka; Build-App firka_wear }
  default      {
    Write-Error "Usage: $MyInvocation.MyCommand.Name [firka|firka_wear|all]"
  }
}
