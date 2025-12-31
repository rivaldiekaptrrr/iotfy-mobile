// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RuleActionAdapter extends TypeAdapter<RuleAction> {
  @override
  final int typeId = 6;

  @override
  RuleAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RuleAction(
      type: fields[0] as RuleActionType,
      mqttTopic: fields[1] as String?,
      mqttPayload: fields[2] as String?,
      notificationTitle: fields[3] as String?,
      notificationBody: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RuleAction obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.mqttTopic)
      ..writeByte(2)
      ..write(obj.mqttPayload)
      ..writeByte(3)
      ..write(obj.notificationTitle)
      ..writeByte(4)
      ..write(obj.notificationBody);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleConfigAdapter extends TypeAdapter<RuleConfig> {
  @override
  final int typeId = 7;

  @override
  RuleConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RuleConfig(
      id: fields[0] as String?,
      name: fields[1] as String,
      isActive: fields[2] as bool,
      sourceWidgetId: fields[3] as String,
      operator: fields[4] as RuleOperator,
      thresholdValue: fields[5] as double,
      actions: (fields[6] as List).cast<RuleAction>(),
      createdAt: fields[7] as DateTime?,
      lastTriggeredAt: fields[8] as DateTime?,
      triggerCount: fields[9] as int,
      dashboardId: fields[10] as String,
      severity: fields[11] as AlarmSeverity,
    );
  }

  @override
  void write(BinaryWriter writer, RuleConfig obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.sourceWidgetId)
      ..writeByte(4)
      ..write(obj.operator)
      ..writeByte(5)
      ..write(obj.thresholdValue)
      ..writeByte(6)
      ..write(obj.actions)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastTriggeredAt)
      ..writeByte(9)
      ..write(obj.triggerCount)
      ..writeByte(10)
      ..write(obj.dashboardId)
      ..writeByte(11)
      ..write(obj.severity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleOperatorAdapter extends TypeAdapter<RuleOperator> {
  @override
  final int typeId = 4;

  @override
  RuleOperator read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RuleOperator.greaterThan;
      case 1:
        return RuleOperator.lessThan;
      case 2:
        return RuleOperator.equals;
      case 3:
        return RuleOperator.greaterOrEqual;
      case 4:
        return RuleOperator.lessOrEqual;
      case 5:
        return RuleOperator.notEquals;
      default:
        return RuleOperator.greaterThan;
    }
  }

  @override
  void write(BinaryWriter writer, RuleOperator obj) {
    switch (obj) {
      case RuleOperator.greaterThan:
        writer.writeByte(0);
        break;
      case RuleOperator.lessThan:
        writer.writeByte(1);
        break;
      case RuleOperator.equals:
        writer.writeByte(2);
        break;
      case RuleOperator.greaterOrEqual:
        writer.writeByte(3);
        break;
      case RuleOperator.lessOrEqual:
        writer.writeByte(4);
        break;
      case RuleOperator.notEquals:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleOperatorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RuleActionTypeAdapter extends TypeAdapter<RuleActionType> {
  @override
  final int typeId = 5;

  @override
  RuleActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RuleActionType.publishMqtt;
      case 1:
        return RuleActionType.showNotification;
      case 2:
        return RuleActionType.showInAppAlert;
      case 3:
        return RuleActionType.logToHistory;
      default:
        return RuleActionType.publishMqtt;
    }
  }

  @override
  void write(BinaryWriter writer, RuleActionType obj) {
    switch (obj) {
      case RuleActionType.publishMqtt:
        writer.writeByte(0);
        break;
      case RuleActionType.showNotification:
        writer.writeByte(1);
        break;
      case RuleActionType.showInAppAlert:
        writer.writeByte(2);
        break;
      case RuleActionType.logToHistory:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
