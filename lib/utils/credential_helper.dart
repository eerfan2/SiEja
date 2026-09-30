import 'dart:convert';
import 'package:crypto/crypto.dart';

class CredentialHelper {
  /// Menghasilkan `credentialKey` yang aman (SHA-256) untuk koleksi `login_siswa`.
  /// [username] dinormalisasi (trim dan lowercase)
  /// [pin] dipertahankan sebagai string 3-digit
  static String generateCredentialKey(String username, String pin) {
    final normalizedUsername = username.trim().toLowerCase();
    
    // Gabungkan dengan format "username:pin"
    final input = '$normalizedUsername:$pin';
    
    // Hash input dengan SHA-256
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
}
