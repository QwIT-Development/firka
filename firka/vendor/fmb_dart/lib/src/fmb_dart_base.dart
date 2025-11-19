import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';


/// usage:
///
/// String encrypted = await FMBCrypt.handleText('encrypt', 'Hello World', 'myPassword');
///
/// String decrypted = await FMBCrypt.handleText('decrypt', encrypted, 'myPassword');
class FMBCrypt {
  static const String _version = "FMB5";
  static const int _saltLength = 32;
  static const int _nonceLength = 12;
  static const int _timestampLength = 8;
  static const int _gcmTagLength = 16;

  static Future<({Uint8List key, Uint8List salt})> generateKey(
      String password, Uint8List? providedSalt) async {
    final salt = providedSalt ?? Uint8List(_saltLength);
    if (providedSalt == null) {
      fillBytesWithSecureRandom(salt);
    }

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: 1000000,
      bits: 256,
    );

    
    final newSecretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final keyBytes = await newSecretKey.extractBytes();
    return (key: Uint8List.fromList(keyBytes), salt: salt);
  }

  static Future<Uint8List> encrypt(dynamic data, String password) async {
    try {
      final keyAndSalt = await generateKey(password, null);
      final key = keyAndSalt.key;
      final salt = keyAndSalt.salt;

      final aesGcm = AesGcm.with256bits();
      final secretKey = SecretKey(key);

      final nonce = Uint8List(_nonceLength);
      fillBytesWithSecureRandom(nonce);

      final versionBytes = utf8.encode(_version);
      final timestamp = Uint8List(_timestampLength);
      final now = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < _timestampLength; i++) {
        timestamp[i] = (now >> (i * 8)) & 0xFF;
      }

      final associatedData =
          Uint8List(versionBytes.length + salt.length + timestamp.length);
      associatedData.setAll(0, versionBytes);
      associatedData.setAll(versionBytes.length, salt);
      associatedData.setAll(versionBytes.length + salt.length, timestamp);

      final inputData = data is Uint8List ? data : utf8.encode(data);

      final cipherText = await aesGcm.encrypt(
        inputData,
        secretKey: secretKey,
        nonce: nonce,
        aad: associatedData,
      );

      final result = Uint8List(versionBytes.length +
          salt.length +
          timestamp.length +
          nonce.length +
          cipherText.cipherText.length +
          cipherText.mac.bytes.length);

      result.setAll(0, versionBytes);
      result.setAll(versionBytes.length, salt);
      result.setAll(versionBytes.length + salt.length, timestamp);
      result.setAll(
          versionBytes.length + salt.length + timestamp.length, nonce);
      result.setAll(
          versionBytes.length + salt.length + timestamp.length + nonce.length,
          cipherText.cipherText);
      result.setAll(
          versionBytes.length +
              salt.length +
              timestamp.length +
              nonce.length +
              cipherText.cipherText.length,
          cipherText.mac.bytes);

      return result;
    } catch (e) {
      throw Exception("Encryption failed: \${e.toString()}");
    }
  }

  static Future<Uint8List> decrypt(
      Uint8List encryptedData, String password) async {
    try {
      if (encryptedData.length <
          _version.length +
              _saltLength +
              _timestampLength +
              _nonceLength +
              _gcmTagLength) {
        throw Exception("Invalid encrypted data: too short");
      }

      final versionBytes = encryptedData.sublist(0, _version.length);
      final version = utf8.decode(versionBytes);
      if (version != _version) {
        throw Exception("Invalid or unsupported file format");
      }

      final salt =
          encryptedData.sublist(_version.length, _version.length + _saltLength);
      final timestamp = encryptedData.sublist(_version.length + _saltLength,
          _version.length + _saltLength + _timestampLength);
      final nonce = encryptedData.sublist(
          _version.length + _saltLength + _timestampLength,
          _version.length + _saltLength + _timestampLength + _nonceLength);
      final cipherTextWithTag = encryptedData.sublist(
          _version.length + _saltLength + _timestampLength + _nonceLength);

      final associatedData =
          Uint8List(versionBytes.length + salt.length + timestamp.length);
      associatedData.setAll(0, versionBytes);
      associatedData.setAll(versionBytes.length, salt);
      associatedData.setAll(versionBytes.length + salt.length, timestamp);

      final keyAndSalt = await generateKey(password, salt);
      final key = keyAndSalt.key;

      final aesGcm = AesGcm.with256bits();
      final secretKey = SecretKey(key);

      final secretBox = SecretBox(
        cipherTextWithTag.sublist(0, cipherTextWithTag.length - _gcmTagLength),
        nonce: nonce,
        mac: Mac(cipherTextWithTag
            .sublist(cipherTextWithTag.length - _gcmTagLength)),
      );

      final decrypted = await aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: associatedData,
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception("Decryption failed: \${e.toString()}");
    }
  }

  static Future<String> handleText(
      String action, String input, String password) async {
    if (password.isEmpty || input.isEmpty) {
      throw Exception("Please provide both input text and a password.");
    }

    try {
      if (action == "encrypt") {
        final encrypted = await encrypt(input, password);
        return base64.encode(encrypted);
      } else if (action == "decrypt") {
        final encryptedData = base64.decode(input);
        final decrypted = await decrypt(encryptedData, password);
        return utf8.decode(decrypted);
      } else {
        throw Exception("Invalid action. Use 'encrypt' or 'decrypt'.");
      }
    } catch (e) {
      throw Exception("Operation failed: \${e.toString()}");
    }
  }
}
