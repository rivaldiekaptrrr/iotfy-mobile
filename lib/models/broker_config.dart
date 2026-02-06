import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'broker_config.g.dart';

/// Tipe certificate authentication
@HiveType(typeId: 20)
enum CertificateType {
  @HiveField(0)
  none,
  @HiveField(1)
  caCertificate,        // CA signed certificate
  @HiveField(2)
  clientCertificate,   // Client certificate + key
  @HiveField(3)
  selfSigned,          // Self-signed certificate
}

/// SSL/TLS Configuration untuk MQTTS
@HiveType(typeId: 21)
class SslConfig extends HiveObject {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  CertificateType certificateType;

  @HiveField(2)
  bool acceptSelfSigned;  // Accept self-signed certificates

  @HiveField(3)
  bool verifyCertificate;  // Verify server certificate

  @HiveField(4)
  String? certificateId;  // Reference ke certificate di secure storage

  @HiveField(5)
  List<String> allowedProtocols;  // TLS 1.2, TLS 1.3, dll

  @HiveField(6)
  bool certificateVerified;  // Status verifikasi certificate

  SslConfig({
    this.enabled = false,
    this.certificateType = CertificateType.none,
    this.acceptSelfSigned = false,
    this.verifyCertificate = true,
    this.certificateId,
    this.allowedProtocols = const ['TLSv1.2', 'TLSv1.3'],
    this.certificateVerified = false,
  });

  SslConfig copyWith({
    bool? enabled,
    CertificateType? certificateType,
    bool? acceptSelfSigned,
    bool? verifyCertificate,
    String? certificateId,
    List<String>? allowedProtocols,
    bool? certificateVerified,
  }) {
    return SslConfig(
      enabled: enabled ?? this.enabled,
      certificateType: certificateType ?? this.certificateType,
      acceptSelfSigned: acceptSelfSigned ?? this.acceptSelfSigned,
      verifyCertificate: verifyCertificate ?? this.verifyCertificate,
      certificateId: certificateId ?? this.certificateId,
      allowedProtocols: allowedProtocols ?? this.allowedProtocols,
      certificateVerified: certificateVerified ?? this.certificateVerified,
    );
  }

  bool get hasCertificate => certificateId != null && certificateId!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'certificateType': certificateType.index,
    'acceptSelfSigned': acceptSelfSigned,
    'verifyCertificate': verifyCertificate,
    'certificateId': certificateId,
    'allowedProtocols': allowedProtocols,
    'certificateVerified': certificateVerified,
  };
}

@HiveType(typeId: 0)
class BrokerConfig extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String host;

  @HiveField(3)
  int port;

  @HiveField(4)
  String? username;

  // Password field - TIDAK dipersist ke Hive, disimpan di Secure Storage
  // Field ini hanya untuk temporary use (connection testing)
  String? password;

  @HiveField(6)
  bool useSsl;

  @HiveField(7)
  String? clientId;

  @HiveField(8)
  int keepAlivePeriod;

  @HiveField(9)
  bool cleanSession;

  // SSL/TLS Configuration
  @HiveField(10)
  SslConfig? sslConfig;

  // Credential reference (untuk know jika credentials tersimpan)
  @HiveField(11)
  bool hasSecureCredentials;  // true jika credentials ada di secure storage

  @HiveField(12)
  DateTime? lastConnected;

  @HiveField(13)
  String? connectionProfile;  // 'development', 'production', 'custom'

  BrokerConfig({
    String? id,
    required this.name,
    required this.host,
    this.port = 1883,
    this.username,
    this.password,
    this.useSsl = false,
    this.clientId,
    this.keepAlivePeriod = 60,
    this.cleanSession = true,
    this.sslConfig,
    this.hasSecureCredentials = false,
    this.lastConnected,
    this.connectionProfile = 'custom',
  }) : id = id ?? const Uuid().v4();

  BrokerConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? useSsl,
    String? clientId,
    int? keepAlivePeriod,
    bool? cleanSession,
    SslConfig? sslConfig,
    bool? hasSecureCredentials,
    DateTime? lastConnected,
    String? connectionProfile,
  }) {
    return BrokerConfig(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
      clientId: clientId ?? this.clientId,
      keepAlivePeriod: keepAlivePeriod ?? this.keepAlivePeriod,
      cleanSession: cleanSession ?? this.cleanSession,
      sslConfig: sslConfig ?? this.sslConfig,
      hasSecureCredentials: hasSecureCredentials ?? this.hasSecureCredentials,
      lastConnected: lastConnected ?? this.lastConnected,
      connectionProfile: connectionProfile ?? this.connectionProfile,
    );
  }

  /// Get effective port berdasarkan SSL configuration
  int getEffectivePort() {
    if (useSsl && sslConfig?.enabled == true) {
      // Return SSL port jika dikonfigurasi, else default 8883
      return port == 1883 ? 8883 : port;
    }
    return port;
  }

  /// Check apakah broker memerlukan certificate
  bool requiresCertificate() {
    return useSsl && sslConfig != null && sslConfig!.certificateType != CertificateType.none;
  }

  /// Check apakah ini MQTTS connection
  bool get isMqtts => useSsl && sslConfig?.enabled == true;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'username': username,
    'useSsl': useSsl,
    'clientId': clientId,
    'keepAlivePeriod': keepAlivePeriod,
    'cleanSession': cleanSession,
    'sslConfig': sslConfig?.toJson(),
    'hasSecureCredentials': hasSecureCredentials,
    'lastConnected': lastConnected?.toIso8601String(),
    'connectionProfile': connectionProfile,
  };
}
