# How to create an upload keystore for Flutter

If you're reading this, you probably want to build the app for release. If you have any questions, reach out on Discord or by email!

## 1. Create the keystore (for v3/v4 signing, EC key)

Open a terminal in this folder and run:

```sh
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg EC -keysize 256 -validity 10000 \
  -alias upload
```

You will be prompted for:
- A password for the keystore
- Your name, organization name (defaults are fine)
- A second password for the „upload” alias (recommended: same as above)

When done, an `upload-keystore.jks` file will be created.

## 2. Create keystore.properties

Create a new file named `keystore.properties` with:

```properties
storeFile=upload-keystore.jks
storePassword=password
keyPassword=password
keyAlias=upload
```

Replace the `password` values with your chosen password(s).