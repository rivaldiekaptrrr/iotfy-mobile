// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'panel_widget_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PanelWidgetConfigAdapter extends TypeAdapter<PanelWidgetConfig> {
  @override
  final int typeId = 3;

  @override
  PanelWidgetConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PanelWidgetConfig(
      id: fields[0] as String?,
      title: fields[1] as String,
      type: fields[2] as WidgetType,
      subscribeTopic: fields[3] as String?,
      publishTopic: fields[4] as String?,
      onPayload: fields[5] as String?,
      offPayload: fields[6] as String?,
      qos: fields[7] as int,
      x: fields[8] as double,
      y: fields[9] as double,
      width: fields[10] as double,
      height: fields[11] as double,
      colorValue: fields[12] as int?,
      iconCodePoint: fields[13] as int?,
      minValue: fields[14] as double?,
      maxValue: fields[15] as double?,
      unit: fields[16] as String?,
      maxDataPoints: fields[17] as int?,
      isMovingMode: fields[18] as bool,
      idleTimeoutSeconds: fields[19] as int,
      mapMarkerIcon: fields[20] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PanelWidgetConfig obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.subscribeTopic)
      ..writeByte(4)
      ..write(obj.publishTopic)
      ..writeByte(5)
      ..write(obj.onPayload)
      ..writeByte(6)
      ..write(obj.offPayload)
      ..writeByte(7)
      ..write(obj.qos)
      ..writeByte(8)
      ..write(obj.x)
      ..writeByte(9)
      ..write(obj.y)
      ..writeByte(10)
      ..write(obj.width)
      ..writeByte(11)
      ..write(obj.height)
      ..writeByte(12)
      ..write(obj.colorValue)
      ..writeByte(13)
      ..write(obj.iconCodePoint)
      ..writeByte(14)
      ..write(obj.minValue)
      ..writeByte(15)
      ..write(obj.maxValue)
      ..writeByte(16)
      ..write(obj.unit)
      ..writeByte(17)
      ..write(obj.maxDataPoints)
      ..writeByte(18)
      ..write(obj.isMovingMode)
      ..writeByte(19)
      ..write(obj.idleTimeoutSeconds)
      ..writeByte(20)
      ..write(obj.mapMarkerIcon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelWidgetConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WidgetTypeAdapter extends TypeAdapter<WidgetType> {
  @override
  final int typeId = 2;

  @override
  WidgetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WidgetType.toggle;
      case 1:
        return WidgetType.button;
      case 2:
        return WidgetType.gauge;
      case 3:
        return WidgetType.lineChart;
      case 4:
        return WidgetType.text;
      case 5:
        return WidgetType.map;
      default:
        return WidgetType.toggle;
    }
  }

  @override
  void write(BinaryWriter writer, WidgetType obj) {
    switch (obj) {
      case WidgetType.toggle:
        writer.writeByte(0);
        break;
      case WidgetType.button:
        writer.writeByte(1);
        break;
      case WidgetType.gauge:
        writer.writeByte(2);
        break;
      case WidgetType.lineChart:
        writer.writeByte(3);
        break;
      case WidgetType.text:
        writer.writeByte(4);
        break;
      case WidgetType.map:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
