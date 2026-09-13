import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordUtils {
  PasswordUtils._();

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
