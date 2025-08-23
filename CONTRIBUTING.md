# Flutter telepítése

A firka androidra való lebuildeléséhez kötelező a saját Flutter fork használata, illetve minden más fajta --release buildhez is.

A Flutter telepítéséhez a dokumentáció [itt](https://docs.flutter.dev/get-started/install) található.

A Flutter zip letöltése helyett [a custom engine zip-et töltsd le](https://git.firka.app/firka/flutter/archive/main.zip)

# Brotli

A firka brotlival compresseli a libflutter-t buildelés közben ezért szükséges a projekt
buildeléséhez hogy a brotli a PATH-ben legyen

## Windows
- Töltsd le a `brotli-x64-windows-static.zip`-et a [google/brotli github repoból](https://github.com/google/brotli/releases/latest)
- Csomagold ki valahol (pl. C:\Users\\<username>\dev\brotli)
- Add hozzá a mappát ahova kicsomagoltad (C:\Users\\<username>\dev\brotli) a PATH-hez
- Ne felejtsd el újraindítani az IDE-det illetve parancssorodat utánna hogy frissüljön a PATH

## Linux/MacOS
Telepítsd fel a brotli packaget a distro-d package managerével

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

## Custom Flutter engine setupolása

```shell
$ git clone https://git.firka.app/firka/flutter
$ cd flutter
$ . dev/tools/envsetup.sh
$ gclient sync -D
$ ./dev/tools/build_release.sh
```

## Release apk buildelése

```shell
$ ./tools/linux/build_apk.sh main
```