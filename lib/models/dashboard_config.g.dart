// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DashboardConfigAdapter extends TypeAdapter<DashboardConfig> {
  @override
  final int typeId = 1;

  @override
  DashboardConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardConfig(
      id: fields[0] as String?,
      name: fields[1] as String,
      brokerId: fields[2] as String,
      widgets: (fields[3] as List?)?.cast<PanelWidgetConfig>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DashboardConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brokerId)
      ..writeByte(3)
      ..write(obj.widgets)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
