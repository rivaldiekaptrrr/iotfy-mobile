import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'encryption_service.dart';

/// Secure Credential Storage Service
/// Menyimpan credentials broker secara aman menggunakan FlutterSecureStorage
class SecureCredentialStorage {
  static final SecureCredentialStorage _instance = SecureCredentialStorage._internal();
  factory SecureCredentialStorage() => _instance;
  SecureCredentialStorage._internal();

  final EncryptionService _encryption = EncryptionService();

  // Keys untuk secure storage
  static const String _brokerPrefix = 'broker_cred_';
  static const String _certPrefix = 'broker_cert_';
  static const String _certKeyPrefix = 'broker_cert_key_';

  /// Simpan username dan password broker terenkripsi
  Future<void> saveBrokerCredentials({
    required String brokerId,
    required String username,
    required String password,
  }) async {
    try {
      await _encryption.saveCredential('$_brokerPrefix${brokerId}_username', username);
      await _encryption.saveCredential('$_brokerPrefix${brokerId}_password', password);

      debugPrint('[SECURE_STORAGE] Credentials saved for broker: $brokerId');
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error saving credentials: $e');
      rethrow;
    }
  }

  /// Ambil username broker
  Future<String?> getUsername(String brokerId) async {
    return await _encryption.getCredential('$_brokerPrefix${brokerId}_username');
  }

  /// Ambil password broker
  Future<String?> getPassword(String brokerId) async {
    return await _encryption.getCredential('$_brokerPrefix${brokerId}_password');
  }

  /// Hapus credentials broker
  Future<void> deleteBrokerCredentials(String brokerId) async {
    try {
      await _encryption.deleteCredential('$_brokerPrefix${brokerId}_username');
      await _encryption.deleteCredential('$_brokerPrefix${brokerId}_password');
      await _encryption.deleteCredential('$_certPrefix$brokerId');
      await _encryption.deleteCredential('$_certKeyPrefix$brokerId');
      
      debugPrint('[SECURE_STORAGE] Credentials deleted for broker: $brokerId');
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error deleting credentials: $e');
      rethrow;
    }
  }

  /// Simpan certificate (enkripsi base64)
  Future<void> saveCertificate({
    required String brokerId,
    required Uint8List certificateBytes,
    Uint8List? privateKeyBytes,
  }) async {
    try {
      // Encode certificates ke base64 string
      final certBase64 = base64Encode(certificateBytes);
      await _encryption.saveCredential('$_certPrefix$brokerId', certBase64);

      // Simpan private key jika ada
      if (privateKeyBytes != null) {
        final keyBase64 = base64Encode(privateKeyBytes);
        await _encryption.saveCredential('$_certKeyPrefix$brokerId', keyBase64);
      }

      debugPrint('[SECURE_STORAGE] Certificate saved for broker: $brokerId');
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error saving certificate: $e');
      rethrow;
    }
  }

  /// Ambil certificate
  Future<Uint8List?> getCertificate(String brokerId) async {
    try {
      final certBase64 = await _encryption.getCredential('$_certPrefix$brokerId');
      if (certBase64 == null) return null;
      return base64Decode(certBase64);
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error getting certificate: $e');
      return null;
    }
  }

  /// Ambil private key
  Future<Uint8List?> getPrivateKey(String brokerId) async {
    try {
      final keyBase64 = await _encryption.getCredential('$_certKeyPrefix$brokerId');
      if (keyBase64 == null) return null;
      return base64Decode(keyBase64);
    } catch (e) {
      debugPrint('[SECURE_STORAGE] Error getting private key: $e');
      return null;
    }
  }

  /// Check apakah broker memiliki credentials tersimpan
  Future<bool> hasCredentials(String brokerId) async {
    return await _encryption.hasCredential('$_brokerPrefix${brokerId}_username');
  }

  /// Check apakah broker memiliki certificate
  Future<bool> hasCertificate(String brokerId) async {
    return await _encryption.hasCredential('$_certPrefix$brokerId');
  }

  /// Check apakah broker memiliki private key
  Future<bool> hasPrivateKey(String brokerId) async {
    return await _encryption.hasCredential('$_certKeyPrefix$brokerId');
  }

  /// Get semua certificate info
  Future<Map<String, dynamic>> getCertificateInfo(String brokerId) async {
    final hasCert = await hasCertificate(brokerId);
    final hasKey = await hasPrivateKey(brokerId);
    
    return {
      'hasCertificate': hasCert,
      'hasPrivateKey': hasKey,
      'isComplete': hasCert && hasKey,
    };
  }
}
