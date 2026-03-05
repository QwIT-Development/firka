# Flutter telepítése

A Flutter telepítéséhez a dokumentáció [itt](https://docs.flutter.dev/get-started/install) található.
A projekt jelenleg a 3.41.2-es Flutter SDK-t használja.

# Keystore

[Secrets dokumentáció](secrets/README.md)

# Fileok generálása

Flutter l10n és egyéb fileok generálása

```shell
$ cd firka # vagy firka_wear
$ dart run scripts/codegen.dart
```

# Android debug build

A dev buildhez nem közelező keystore használata
```shell
$ cd firka
$ Flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
```

# Android release build

A release buildhez közelező egy keystore használata.

## Release appbundle buildelése (firka és firka_wear)

```shell
$ ./build.sh
```