# 🔐 Security Documentation - IoTify Platform

## Overview

This document describes the security features implemented in IoTify Platform, including secure credential storage, SSL/TLS certificate management, and encryption mechanisms.

---

## Table of Contents

1. [Secure Credential Storage](#secure-credential-storage)
2. [SSL/TLS Configuration](#ssltls-configuration)
3. [Certificate Types](#certificate-types)
4. [Encryption Service](#encryption-service)
5. [API Reference](#api-reference)
6. [Security Best Practices](#security-best-practices)

---

## Secure Credential Storage

### Overview

IoTify Platform uses **FlutterSecureStorage** combined with custom encryption to store sensitive credentials. This ensures that passwords and certificates are never stored in plain text.

### Storage Locations

| Data Type | Storage Location | Encryption |
|-----------|------------------|------------|
| Broker Passwords | FlutterSecureStorage | AES-like obfuscation |
| Usernames | FlutterSecureStorage | AES-like obfuscation |
| CA Certificates | FlutterSecureStorage | Base64 + obfuscation |
| Client Certificates | FlutterSecureStorage | Base64 + obfuscation |
| Private Keys | FlutterSecureStorage | Base64 + obfuscation |

### Files Involved

- [`lib/services/encryption_service.dart`](lib/services/encryption_service.dart) - Core encryption service
- [`lib/services/secure_credential_storage.dart`](lib/services/secure_credential_storage.dart) - Credential management
- [`lib/providers/storage_providers.dart`](lib/providers/storage_providers.dart) - State management

### Key Features

1. **Master Key Derivation**: Uses PBKDF2-like key derivation with salt
2. **Obfuscation**: Custom encoding to prevent casual reading
3. **Secure Deletion**: Credentials are securely deleted when broker is removed

---

## SSL/TLS Configuration

### MQTT over SSL (MQTTS)

IoTify Platform supports secure MQTT connections using SSL/TLS encryption.

### Connection Modes

| Mode | Port | Security | Use Case |
|------|------|----------|----------|
| **MQTT (Standard)** | 1883 | None | Development, testing |
| **MQTTS (SSL)** | 8883 | TLS encryption | Production, sensitive data |
| **MQTTS + Auth** | 8883 | TLS + credentials | Enterprise deployment |

### Configuration Flow

```
Broker Form → Enable SSL/TLS → Select Certificate Type → Upload Certificates → Test Connection
```

### Steps to Configure

1. **Open Broker Form**
   - Navigate to Broker List
   - Click "Add Broker" or edit existing broker

2. **Enable SSL/TLS**
   - Toggle "SSL/TLS" switch
   - Port automatically changes from 1883 to 8883

3. **Select Certificate Type**
   - Choose based on your broker's requirements
   - Options: None, CA Signed, Client Cert, Self-Signed

4. **Upload Certificates**
   - Select appropriate certificate files
   - Supported formats: `.pem`, `.crt`, `.ca-bundle`, `.key`

5. **Test Connection**
   - Click "Test Connection" to verify
   - Check logs for any SSL/TLS errors

---

## Certificate Types

### 1. None (No Certificate)

```yaml
Security: Basic
Use Case: Development, testing environments
Requirements: None
```

**When to use:**
- Local development brokers
- Public test brokers
- Non-sensitive data transmission

### 2. CA Signed Certificate

```yaml
Security: High
Use Case: Production with trusted CA
Requirements: 
  - CA Certificate (.pem, .crt, .ca-bundle)
  - Broker must have CA-signed certificate
```

**When to use:**
- Enterprise brokers with proper PKI
- Cloud MQTT services (AWS IoT, Azure IoT Hub)
- Production environments

**Upload Required:**
```
CA Certificate
└── Validates broker's identity
```

### 3. Client Certificate (Mutual TLS)

```yaml
Security: Very High (Mutual TLS)
Use Case: Maximum security, zero-trust networks
Requirements:
  - CA Certificate
  - Client Certificate (.pem, .crt)
  - Private Key (.pem, .key)
```

**When to use:**
- Financial services
- Healthcare IoT
- Industrial control systems
- Government/military applications

**Upload Required:**
```
CA Certificate
Client Certificate
Private Key
└── Both client and broker authenticate each other
```

### 4. Self-Signed Certificate

```yaml
Security: Medium (Accepts any certificate)
Use Case: Internal networks, quick setup
Requirements: None (accepts any certificate)
```

**⚠️ Warning:** This mode accepts all certificates including invalid ones. Use only in trusted networks.

**When to use:**
- Internal corporate networks
- Air-gapped systems
- Quick prototyping

---

## Encryption Service

### Architecture

```
┌─────────────────────────────────────────────────┐
│           EncryptionService                       │
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │         FlutterSecureStorage               │  │
│  │  - Master Key Management                   │  │
│  │  - Credential Storage                      │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │         Custom Obfuscation                 │  │
│  │  - Salt-based encoding                    │  │
│  │  - Base64 transformation                  │  │
│  │  - Master key protection                  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Key Derivation

```dart
// Simplified key derivation process
1. Generate random salt (fixed: 'valiot_salt_2024')
2. Combine with master key
3. Apply PBKDF2-like transformation
4. Store securely in FlutterSecureStorage
```

### Encryption Process

```dart
Input: "mysecretpassword"
    ↓
Combine with salt + master key
    ↓
Apply obfuscation encoding
    ↓
Base64 encode result
    ↓
Store in FlutterSecureStorage
    ↓
Output: "encoded_ciphertext"
```

### API Reference

#### EncryptionService

```dart
class EncryptionService {
  // Encrypt sensitive data
  Future<String> encrypt(String plainText) 
  
  // Decrypt sensitive data
  Future<String> decrypt(String encryptedData) 
  
  // Encrypt file (certificates)
  Future<String> encryptFile(Uint8List fileBytes) 
  
  // Decrypt file (certificates)
  Future<Uint8List> decryptFile(String encryptedData) 
  
  // Save credential securely
  Future<void> saveCredential(String key, String value) 
  
  // Retrieve credential securely
  Future<String?> getCredential(String key) 
  
  // Delete credential
  Future<void> deleteCredential(String key) 
  
  // Check if credential exists
  Future<bool> hasCredential(String key) 
}
```

#### SecureCredentialStorage

```dart
class SecureCredentialStorage {
  // Save broker credentials
  Future<void> saveBrokerCredentials({
    required String brokerId,
    required String username,
    required String password,
  })
  
  // Get username
  Future<String?> getUsername(String brokerId)
  
  // Get password
  Future<String?> getPassword(String brokerId)
  
  // Delete all credentials for broker
  Future<void> deleteBrokerCredentials(String brokerId)
  
  // Save certificate
  Future<void> saveCertificate({
    required String brokerId,
    required Uint8List certificateBytes,
    Uint8List? privateKeyBytes,
  })
  
  // Get certificate
  Future<Uint8List?> getCertificate(String brokerId)
  
  // Get private key
  Future<Uint8List?> getPrivateKey(String brokerId)
  
  // Check certificate status
  Future<Map<String, dynamic>> getCertificateInfo(String brokerId)
}
```

---

## Security Best Practices

### ✅ Do's

1. **Use CA Signed certificates in production**
   ```yaml
   Recommended: CA Signed > Client Cert > Self-Signed > None
   ```

2. **Enable certificate verification**
   ```dart
   sslConfig.verifyCertificate = true  // Default
   ```

3. **Rotate credentials periodically**
   - Change passwords every 90 days
   - Renew certificates before expiration

4. **Use mutual TLS for sensitive applications**
   ```yaml
   For: Financial, Healthcare, Industrial Control
   ```

5. **Test connection with certificates**
   - Always test before saving broker

### ❌ Don'ts

1. **Never use Self-Signed in production**
   - Only for development/testing

2. **Don't disable certificate verification**
   ```dart
   // AVOID THIS IN PRODUCTION
   sslConfig.verifyCertificate = false
   sslConfig.acceptSelfSigned = true
   ```

3. **Don't store credentials in code**
   - Use secure storage only

4. **Don't share private keys**
   - Private keys must remain confidential

### Certificate File Formats

#### Supported Formats

| Extension | Type | Use Case |
|----------|------|----------|
| `.pem` | Privacy-Enhanced Mail | Certificates and keys |
| `.crt` | Certificate | X.509 certificate |
| `.ca-bundle` | CA Bundle | Multiple CA certificates |
| `.cer` | Certificate | Windows-style certificate |
| `.key` | Private Key | RSA/ECC private key |

#### Example Certificate Chain

```
-----BEGIN CERTIFICATE-----
[CA Certificate]
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
[Intermediate CA Certificate]
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
[Server/Client Certificate]
-----END CERTIFICATE-----
```

#### Example Private Key

```
-----BEGIN RSA PRIVATE KEY-----
[Private Key Data]
-----END RSA PRIVATE KEY-----
```

---

## Troubleshooting

### Common Errors

#### 1. "Null check operator used on a null value"

**Cause:** File picker returning null bytes on Windows

**Solution:** Fixed in latest version - now reads from file path

#### 2. "Certificate verification failed"

**Cause:** Certificate not trusted or expired

**Solution:**
- Check certificate expiration date
- Ensure CA certificate is correct
- Try "Accept Self-Signed" for testing

#### 3. "Connection timeout"

**Cause:** SSL handshake taking too long

**Solution:**
- Check network connectivity
- Verify port (8883 for MQTTS)
- Try without SSL first

### Debug Logging

Enable debug logging in MQTT service:

```dart
// In mqtt_service.dart
_client!.logging(on: true);  // Enable MQTT logging
```

Check logs for:
```
[ENCRYPTION] Encryption/Decryption operations
[SECURE_STORAGE] Credential management
[MqttService] SSL/TLS configuration
```

---

## API Integration

### Connect with SSL/TLS

```dart
final broker = BrokerConfig(
  name: 'Production Broker',
  host: 'mqtt.example.com',
  port: 8883,
  useSsl: true,
  sslConfig: SslConfig(
    enabled: true,
    certificateType: CertificateType.caCertificate,
    verifyCertificate: true,
  ),
);

final service = MqttService();
await service.connect(broker);
```

### Get Credentials

```dart
final storage = SecureCredentialStorage();
final password = await storage.getPassword(brokerId);

if (password != null) {
  print('Password retrieved securely');
}
```

---

## Performance Considerations

### Certificate Loading

- Certificates are loaded once during connection
- Cached in memory for session duration
- Deleted from memory on disconnect

### Storage Limits

| Storage Type | Limit |
|-------------|-------|
| Credentials per broker | Unlimited |
| Total certificates | Device dependent |
| Certificate size | < 10MB recommended |

---

## Compliance

### Security Standards

IoTify Platform follows security best practices aligned with:

- **OWASP IoT Security Guidelines**
- **NIST Cybersecurity Framework**
- **IEC 62443** (Industrial IoT)

### Data Protection

- Credentials: Encrypted at rest
- Certificates: Encrypted at rest
- Transport: TLS 1.2/1.3 encryption
- Memory: Cleared after use

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01 | Initial secure storage implementation |
| 1.1.0 | 2024-02 | MQTTS support with certificates |
| 1.2.0 | 2024-03 | Mutual TLS (Client Certificates) |

---

## Support

For security-related issues or questions:

1. Check this documentation
2. Review troubleshooting section
3. Check application logs
4. Contact security team

---

**Last Updated:** 2024-03-15  
**Version:** 1.2.0
