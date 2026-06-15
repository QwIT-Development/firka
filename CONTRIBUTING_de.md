# Flutter installieren

Die Dokumentation zur Installation von Flutter findest du [hier](https://docs.flutter.dev/get-started/install).
Das Projekt verwendet derzeit das Flutter SDK 3.41.2.

# Keystore

[Dokumentation zu Secrets](secrets/README.md)

# Dateien generieren

Flutter-L10N-Dateien und andere Dateien generieren

```shell
$ cd firka # oder firka_wear
$ dart run scripts/codegen.dart
```

# Android-Debug-Build

Für den Dev-Build ist kein Keystore erforderlich
```shell
$ cd firka
$ flutter build apk --debug --target-platform android-arm,android-arm64,android-x64
```

# Android-Release-Build

Der Release-Build erfordert die Verwendung eines Keystores.

## Erstellen des Release-Appbundles (firka und firka_wear)

```shell
$ ./build.sh
```
