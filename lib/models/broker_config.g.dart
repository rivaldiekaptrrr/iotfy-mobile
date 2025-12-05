// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broker_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      password: fields[5] as String?,
      useSsl: fields[6] as bool,
      clientId: fields[7] as String?,
      keepAlivePeriod: fields[8] as int,
      cleanSession: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BrokerConfig obj) {
    writer
      ..writeByte(10)
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
      ..writeByte(5)
      ..write(obj.password)
      ..writeByte(6)
      ..write(obj.useSsl)
      ..writeByte(7)
      ..write(obj.clientId)
      ..writeByte(8)
      ..write(obj.keepAlivePeriod)
      ..writeByte(9)
      ..write(obj.cleanSession);
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
