// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmEventAdapter extends TypeAdapter<AlarmEvent> {
  @override
  final int typeId = 10;

  @override
  AlarmEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmEvent(
      id: fields[0] as String?,
      ruleId: fields[1] as String,
      ruleName: fields[2] as String,
      sensorName: fields[3] as String,
      severity: fields[4] as AlarmSeverity,
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime?,
      status: fields[7] as AlarmStatus,
      triggerValue: fields[8] as double,
      thresholdValue: fields[9] as double,
      condition: fields[10] as String,
      acknowledgedTime: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmEvent obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ruleId)
      ..writeByte(2)
      ..write(obj.ruleName)
      ..writeByte(3)
      ..write(obj.sensorName)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.triggerValue)
      ..writeByte(9)
      ..write(obj.thresholdValue)
      ..writeByte(10)
      ..write(obj.condition)
      ..writeByte(11)
      ..write(obj.acknowledgedTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmSeverityAdapter extends TypeAdapter<AlarmSeverity> {
  @override
  final int typeId = 8;

  @override
  AlarmSeverity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmSeverity.critical;
      case 1:
        return AlarmSeverity.major;
      case 2:
        return AlarmSeverity.minor;
      default:
        return AlarmSeverity.critical;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmSeverity obj) {
    switch (obj) {
      case AlarmSeverity.critical:
        writer.writeByte(0);
        break;
      case AlarmSeverity.major:
        writer.writeByte(1);
        break;
      case AlarmSeverity.minor:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSeverityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmStatusAdapter extends TypeAdapter<AlarmStatus> {
  @override
  final int typeId = 9;

  @override
  AlarmStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmStatus.active;
      case 1:
        return AlarmStatus.acknowledged;
      case 2:
        return AlarmStatus.cleared;
      default:
        return AlarmStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmStatus obj) {
    switch (obj) {
      case AlarmStatus.active:
        writer.writeByte(0);
        break;
      case AlarmStatus.acknowledged:
        writer.writeByte(1);
        break;
      case AlarmStatus.cleared:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
