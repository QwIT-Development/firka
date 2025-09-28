# Installing flutter

The documentation for installing flutter can be found [here](https://docs.flutter.dev/get-started/install).

# Keystore

[Secrets docs](secrets/README_en.md)

# Flutter l10n

Generating flutter l10n files

```shell
flutter gen-l10n --template-arb-file app_hu.arb
```

# Android debug build

The dev build doesn't require using a custom keystore
```shell
$ cd firka
$ flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
```

# Android release build

The release build requires using a custom keystore and our custom flutter fork

## Building the release apk

```shell
$ ./tools/linux/build_apk.sh main
```