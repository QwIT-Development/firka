# FMBCrypt Dart Library 5
Pretty easy to install and secure, I think...

## Usage:
**Encryption**:
```dart
await FMBCrypt.handleText('encrypt', plaintext, password);
```
**Decryption**:
```dart
await FMBCrypt.handleText('decrypt', ciphertext, password);
```

## Under the hood
### Key generation
1. Generates a random 32-byte salt
2. Convert password into bytes with UTF-8 encoding
3. PBKDF2 the password (SHA-512, 1,000,000x, 256 bits, salt)
4. Secure the final 32-byte key
### Encryption
1. Generates a 12-byte nonce for GCM
2. Creates associated data (application ID + version + salt + timestamp) for authentication
3. Sets up AES-256 in GCM mode (authenticated encryption)
4. Encrypt bytes using AES-GCM with associated data
5. Combine the data in the following order:
    - First 4 bytes: Version header ("FMB5")
    - Next 32 bytes: Salt
    - Next 8 bytes: Timestamp
    - Next 12 bytes: GCM Nonce
    - Remaining: Encrypted data + 16-byte authentication tag
