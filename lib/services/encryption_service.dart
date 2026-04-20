import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encryption Service untuk menyimpan data sensitif
/// Menggunakan FlutterSecureStorage dengan base64 encoding + simple obfuscation
/// NOTE: Untuk security tingkat tinggi, pertimbangkan library encryption tambahan
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Key identifiers
  static const String _masterKeyIdentifier = 'valiot_master_key';
  static const String _salt = 'valiot_salt_2024';

  /// Generate simple encoded key
  String _generateKey() {
    final bytes = Uint8List.fromList(
      List.generate(32, (i) => (DateTime.now().millisecondsSinceEpoch + i * 7) % 256)
    );
    return base64Encode(bytes);
  }

  /// Obfuscate string (simple encoding untuk prevent casual reading)
  String _obfuscate(String input) {
    final chars = input.split('');
    final obfuscated = chars.map((c) {
      final code = c.codeUnitAt(0) + 5;
      return String.fromCharCode(code);
    }).toList();
    return base64Encode(utf8.encode(obfuscated.join()));
  }

  /// Deobfuscate string
  String _deobfuscate(String input) {
    try {
      final decoded = base64Decode(input);
      final chars = utf8.decode(decoded).split('');
      final deobfuscated = chars.map((c) {
        final code = c.codeUnitAt(0) - 5;
        return String.fromCharCode(code);
      }).join();
      return deobfuscated;
    } catch (e) {
      return '';
    }
  }

  /// Enkripsi data sensitif
  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) return '';

    try {
      // Get atau create master key
      String? masterKey = await _storage.read(key: _masterKeyIdentifier);
      if (masterKey == null) {
        masterKey = _generateKey();
        await _storage.write(key: _masterKeyIdentifier, value: masterKey);
      }

      // Simple obfuscation + encoding
      final combined = '$_salt:$masterKey:$plainText';
      return _obfuscate(combined);
    } catch (e) {
      debugPrint('[ENCRYPTION] Encryption error: $e');
      return '';
    }
  }

  /// Dekripsi data sensitif
  Future<String> decrypt(String encryptedData) async {
    if (encryptedData.isEmpty) return '';

    try {
      final deobfuscated = _deobfuscate(encryptedData);
      final parts = deobfuscated.split(':');
      
      if (parts.length < 3) return '';
      if (parts[0] != _salt) return '';
      
      return parts.sublist(2).join(':');
    } catch (e) {
      debugPrint('[ENCRYPTION] Decryption error: $e');
      return '';
    }
  }

  /// Enkripsi file (untuk certificates)
  Future<String> encryptFile(Uint8List fileBytes) async {
    try {
      String? masterKey = await _storage.read(key: _masterKeyIdentifier);
      if (masterKey == null) {
        masterKey = _generateKey();
        await _storage.write(key: _masterKeyIdentifier, value: masterKey);
      }

      // Encode file bytes dengan key
      final combined = '$_salt:$masterKey:${base64Encode(fileBytes)}';
      return _obfuscate(combined);
    } catch (e) {
      debugPrint('[ENCRYPTION] File encryption error: $e');
      return '';
    }
  }

  /// Dekripsi file (untuk certificates)
  Future<Uint8List> decryptFile(String encryptedData) async {
    try {
      final deobfuscated = _deobfuscate(encryptedData);
      final parts = deobfuscated.split(':');
      
      if (parts.length < 3) return Uint8List(0);
      if (parts[0] != _salt) return Uint8List(0);
      
      return base64Decode(parts.sublist(2).join(':'));
    } catch (e) {
      debugPrint('[ENCRYPTION] File decryption error: $e');
      return Uint8List(0);
    }
  }

  /// Simpan credential dengan secure storage
  Future<void> saveCredential(String key, String value) async {
    final encrypted = await encrypt(value);
    await _storage.write(key: key, value: encrypted);
  }

  /// Ambil credential dari secure storage
  Future<String?> getCredential(String key) async {
    final encrypted = await _storage.read(key: key);
    if (encrypted == null) return null;
    return await decrypt(encrypted);
  }

  /// Hapus credential
  Future<void> deleteCredential(String key) async {
    await _storage.delete(key: key);
  }

  /// Check apakah credential exists
  Future<bool> hasCredential(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}
