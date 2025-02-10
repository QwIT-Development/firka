# hogyan hozz létre upload-keystore-t flutterhez?

ha ezt olvasod, akkor valószínűleg szeretnéd a refilc appot build-elni. ha bármi kérdésed lenne, nyugodtan keress minket discordon, vagy akár emailben is!

## 1. keystore létrehozása

először, nyiss egy terminált ebben a mappában és futtasd ezt a parancsot:

```sh
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

ezután meg kell adnod néhány adatot:
- egy jelszót a keystore-hoz (ezt jegyezd meg!)
- nevedet, szervezeted nevét (nyugodtan hagyhatod alapértelmezetten)
- egy második jelszót az „upload” aliashoz (ajánlott az előzőt használni)

ha minden jól megy, egy `upload-keystore.jks` fájl létrejön.

## 3. keystore.properties létrehozása

hozz létre egy új fájlt `keystore.properties` néven, és írd bele a következőt:

```properties
storeFile=upload-keystore.jks
storePassword=password
keyPassword=password
keyAlias=upload
```

cseréld ki a `password` részeket, természetesen a választott jelszavadra.

## 4. secrets mappa kizárása a gitből

már beleraktuk a .gitignore mappába a kizárását ennek, ezen nem kell aggódnod.

készen is vagy, sok sikert!
