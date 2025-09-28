# Flutter telepítése

A Flutter telepítéséhez a dokumentáció [itt](https://docs.flutter.dev/get-started/install) található.

# Keystore

[Secrets dokumentáció](secrets/README.md)

# Flutter l10n

Flutter l10n fileok generálása

```shell
Flutter gen-l10n --template-arb-file app_hu.arb
```

# Android debug build

A dev buildhez nem közelező keystore használata
```shell
$ cd firka
$ Flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
```

# Android release build

A release buildhez közelező egy keystore használata, illetve a saját Flutter engineünk használata.

## Release apk buildelése

```shell
$ ./tools/linux/build_apk.sh main
```