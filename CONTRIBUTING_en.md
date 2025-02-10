# Installing flutter

The documentation for installing flutter can be found [here](https://docs.flutter.dev/get-started/install).

# Brotli

Firka uses brotli to compress libflutter during the build process to make the app smaller,
so building Firka requires you to have brotli in your path

## Windows
- Download `brotli-x64-windows-static.zip` from [google/brotli](https://github.com/google/brotli/releases/latest)
- Extract it to somewhere like C:\Users\\<username>\dev\brotli
- Add the directory (ex. C:\Users\\<username>\dev\brotli) to your PATH
- Don't forget to restart your IDE or terminal sessions for the PATH variable to update

## Linux/MacOS
Install it using your distro's package manager

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

## Setting up our flutter engine fork

```shell
$ git clone https://git.firka.app/firka/flutter
$ cd flutter
$ . dev/tools/envsetup.sh
$ gclient sync -D
$ ./dev/tools/build_release.sh
```

## Building the release apk

```shell
$ ./tools/linux/build_apk.sh main
```