# Installing Flutter

Flutter installation documentation can be found [here](https://docs.flutter.dev/get-started/install).
The project currently uses Flutter SDK 3.41.2.

# Keystore

[Secrets documentation](secrets/README.md)

# Generating files

Generating Flutter l10n and other files

```shell
$ cd firka # or firka_wear
$ dart run scripts/codegen.dart
```

# Android debug build

The dev build does not require using a keystore
```shell
$ cd firka
$ flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
```

# Android release build

The release build requires using a keystore.

## Building the release appbundle (firka and firka_wear)

```shell
$ ./build.sh
```
