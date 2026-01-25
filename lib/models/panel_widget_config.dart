import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'panel_widget_config.g.dart';

@HiveType(typeId: 2)
enum WidgetType {
  @HiveField(0) toggle,
  @HiveField(1) button,
  @HiveField(2) gauge,
  @HiveField(3) lineChart,
  @HiveField(4) text,
  @HiveField(5) map,
  @HiveField(6) slider,
  @HiveField(7) alarm,
  @HiveField(8) statusIndicator,
  @HiveField(9) kpiCard,
  @HiveField(10) barChart,
  @HiveField(11) liquidTank,
  @HiveField(12) radialGauge,
  @HiveField(13) knob,
  @HiveField(14) battery,
  @HiveField(15) terminal,
  @HiveField(16) segmentedSwitch,
  @HiveField(17) linearGauge,
  @HiveField(18) joystick,
  @HiveField(19) compass,
  @HiveField(20) keypad,
  @HiveField(21) iconMatrix,
}

@HiveType(typeId: 3)
class PanelWidgetConfig extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String title;
  @HiveField(2) WidgetType type;
  @HiveField(3) String? subscribeTopic;
  @HiveField(4) String? publishTopic;
  @HiveField(5) String? onPayload;
  @HiveField(6) String? offPayload;
  @HiveField(7) int qos;
  @HiveField(8) double x;
  @HiveField(9) double y;
  @HiveField(10) double width;
  @HiveField(11) double height;
  @HiveField(12) int? colorValue;
  @HiveField(13) int? iconCodePoint;
  @HiveField(14) double? minValue;
  @HiveField(15) double? maxValue;
  @HiveField(16) String? unit;
  @HiveField(17) int? maxDataPoints;
  @HiveField(18) bool isMovingMode;
  @HiveField(19) int idleTimeoutSeconds;
  @HiveField(20) int? mapMarkerIcon;  // Icon number 1-21 untuk Map Tracker
  @HiveField(21) double? warningThreshold;
  @HiveField(22) double? criticalThreshold;
  @HiveField(23) List<String>? options;
  @HiveField(24) bool isJsonPayload;
  @HiveField(25) String? jsonPath; // For Subscribe
  @HiveField(26) String? jsonPattern; // For Publish
  @HiveField(27) int decimalPlaces; // 0 = integer, 1-2 = float precision

  PanelWidgetConfig({
    String? id,
    required this.title,
    required this.type,
    this.subscribeTopic,
    this.publishTopic,
    this.onPayload = 'ON',
    this.offPayload = 'OFF',
    this.qos = 1,
    this.x = 0,
    this.y = 0,
    this.width = 1,
    this.height = 1,
    this.colorValue,
    this.iconCodePoint,
    this.minValue = 0,
    this.maxValue = 100,
    this.unit,
    this.maxDataPoints = 50,
    this.isMovingMode = false,
    this.idleTimeoutSeconds = 10,
    this.mapMarkerIcon,
    this.warningThreshold,
    this.criticalThreshold,
    this.options,
    this.isJsonPayload = false,
    this.jsonPath,
    this.jsonPattern,
    this.decimalPlaces = 1,
  }) : id = id ?? const Uuid().v4();

  Color get color => colorValue != null ? Color(colorValue!) : Colors.blue;

  IconData? get icon {
    if (iconCodePoint == null) return null;
    return IconData(iconCodePoint!, fontFamily: 'MaterialIcons');
  }

  PanelWidgetConfig copyWith({
    String? title,
    WidgetType? type,
    String? subscribeTopic,
    String? publishTopic,
    String? onPayload,
    String? offPayload,
    int? qos,
    double? x,
    double? y,
    double? width,
    double? height,
    int? colorValue,
    int? iconCodePoint,
    double? minValue,
    double? maxValue,
    String? unit,
    int? maxDataPoints,
    bool? isMovingMode,
    int? idleTimeoutSeconds,
    int? mapMarkerIcon,
    double? warningThreshold,
    double? criticalThreshold,
    List<String>? options,
    bool? isJsonPayload,
    String? jsonPath,
    String? jsonPattern,
    int? decimalPlaces,
  }) {
    return PanelWidgetConfig(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      subscribeTopic: subscribeTopic ?? this.subscribeTopic,
      publishTopic: publishTopic ?? this.publishTopic,
      onPayload: onPayload ?? this.onPayload,
      offPayload: offPayload ?? this.offPayload,
      qos: qos ?? this.qos,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      unit: unit ?? this.unit,
      maxDataPoints: maxDataPoints ?? this.maxDataPoints,
      isMovingMode: isMovingMode ?? this.isMovingMode,
      idleTimeoutSeconds: idleTimeoutSeconds ?? this.idleTimeoutSeconds,
      mapMarkerIcon: mapMarkerIcon ?? this.mapMarkerIcon,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      options: options ?? this.options,
      isJsonPayload: isJsonPayload ?? this.isJsonPayload,
      jsonPath: jsonPath ?? this.jsonPath,
      jsonPattern: jsonPattern ?? this.jsonPattern,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }
}