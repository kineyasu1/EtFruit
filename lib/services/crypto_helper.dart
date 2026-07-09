import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PBKDF2 {
  static Uint8List deriveKey(
    String password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final numBlocks = (keyLength / 32).ceil();
    final result = BytesBuilder();

    for (int i = 1; i <= numBlocks; i++) {
      // Concatenate salt and 4-byte block index (big-endian)
      final blockIndexBytes = ByteData(4)..setUint32(0, i, Endian.big);
      final saltAndIndex = Uint8List(salt.length + 4)
        ..setAll(0, salt)
        ..setAll(salt.length, blockIndexBytes.buffer.asUint8List());

      var u = hmac.convert(saltAndIndex).bytes;
      var f = Uint8List.fromList(u);

      for (int j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        for (int k = 0; k < f.length; k++) {
          f[k] ^= u[k];
        }
      }
      result.add(f);
    }

    return result.toBytes().sublist(0, keyLength);
  }

  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  static String hashPassword(String password, String salt) {
    final saltBytes = base64.decode(salt);
    final keyBytes = deriveKey(password, saltBytes, 100, 32);
    return base64.encode(keyBytes);
  }
}
