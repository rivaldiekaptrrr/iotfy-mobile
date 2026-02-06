// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broker_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SslConfigAdapter extends TypeAdapter<SslConfig> {
  @override
  final int typeId = 21;

  @override
  SslConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SslConfig(
      enabled: fields[0] as bool,
      certificateType: fields[1] as CertificateType,
      acceptSelfSigned: fields[2] as bool,
      verifyCertificate: fields[3] as bool,
      certificateId: fields[4] as String?,
      allowedProtocols: (fields[5] as List).cast<String>(),
      certificateVerified: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SslConfig obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.certificateType)
      ..writeByte(2)
      ..write(obj.acceptSelfSigned)
      ..writeByte(3)
      ..write(obj.verifyCertificate)
      ..writeByte(4)
      ..write(obj.certificateId)
      ..writeByte(5)
      ..write(obj.allowedProtocols)
      ..writeByte(6)
      ..write(obj.certificateVerified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SslConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BrokerConfigAdapter extends TypeAdapter<BrokerConfig> {
  @override
  final int typeId = 0;

  @override
  BrokerConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrokerConfig(
      id: fields[0] as String?,
      name: fields[1] as String,
      host: fields[2] as String,
      port: fields[3] as int,
      username: fields[4] as String?,
      useSsl: fields[6] as bool,
      clientId: fields[7] as String?,
      keepAlivePeriod: fields[8] as int,
      cleanSession: fields[9] as bool,
      sslConfig: fields[10] as SslConfig?,
      hasSecureCredentials: fields[11] as bool,
      lastConnected: fields[12] as DateTime?,
      connectionProfile: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BrokerConfig obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.host)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.username)
      ..writeByte(6)
      ..write(obj.useSsl)
      ..writeByte(7)
      ..write(obj.clientId)
      ..writeByte(8)
      ..write(obj.keepAlivePeriod)
      ..writeByte(9)
      ..write(obj.cleanSession)
      ..writeByte(10)
      ..write(obj.sslConfig)
      ..writeByte(11)
      ..write(obj.hasSecureCredentials)
      ..writeByte(12)
      ..write(obj.lastConnected)
      ..writeByte(13)
      ..write(obj.connectionProfile);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrokerConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CertificateTypeAdapter extends TypeAdapter<CertificateType> {
  @override
  final int typeId = 20;

  @override
  CertificateType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CertificateType.none;
      case 1:
        return CertificateType.caCertificate;
      case 2:
        return CertificateType.clientCertificate;
      case 3:
        return CertificateType.selfSigned;
      default:
        return CertificateType.none;
    }
  }

  @override
  void write(BinaryWriter writer, CertificateType obj) {
    switch (obj) {
      case CertificateType.none:
        writer.writeByte(0);
        break;
      case CertificateType.caCertificate:
        writer.writeByte(1);
        break;
      case CertificateType.clientCertificate:
        writer.writeByte(2);
        break;
      case CertificateType.selfSigned:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificateTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
