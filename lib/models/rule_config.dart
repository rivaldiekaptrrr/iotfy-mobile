import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'rule_config.g.dart';

@HiveType(typeId: 4)
enum RuleOperator {
  @HiveField(0) greaterThan,      // >
  @HiveField(1) lessThan,         // <
  @HiveField(2) equals,           // ==
  @HiveField(3) greaterOrEqual,   // >=
  @HiveField(4) lessOrEqual,      // <=
  @HiveField(5) notEquals,        // !=
}

@HiveType(typeId: 5)
enum RuleActionType {
  @HiveField(0) publishMqtt,
  @HiveField(1) showNotification,
  @HiveField(2) showInAppAlert,
  @HiveField(3) logToHistory,
}

@HiveType(typeId: 6)
class RuleAction {
  @HiveField(0) final RuleActionType type;
  @HiveField(1) final String? mqttTopic;      // For publishMqtt
  @HiveField(2) final String? mqttPayload;    // For publishMqtt
  @HiveField(3) final String? notificationTitle;
  @HiveField(4) final String? notificationBody;

  const RuleAction({
    required this.type,
    this.mqttTopic,
    this.mqttPayload,
    this.notificationTitle,
    this.notificationBody,
  });
}

@HiveType(typeId: 7)
class RuleConfig extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) bool isActive;
  
  // Condition
  @HiveField(3) String sourceWidgetId;        // Which widget to monitor
  @HiveField(4) RuleOperator operator;
  @HiveField(5) double thresholdValue;
  
  // Actions
  @HiveField(6) List<RuleAction> actions;
  
  // Metadata
  @HiveField(7) DateTime createdAt;
  @HiveField(8) DateTime? lastTriggeredAt;
  @HiveField(9) int triggerCount;
  @HiveField(10) String dashboardId;          // Which dashboard this rule belongs to

  RuleConfig({
    String? id,
    required this.name,
    this.isActive = true,
    required this.sourceWidgetId,
    required this.operator,
    required this.thresholdValue,
    required this.actions,
    DateTime? createdAt,
    this.lastTriggeredAt,
    this.triggerCount = 0,
    required this.dashboardId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String getOperatorSymbol() {
    switch (operator) {
      case RuleOperator.greaterThan:
        return '>';
      case RuleOperator.lessThan:
        return '<';
      case RuleOperator.equals:
        return '==';
      case RuleOperator.greaterOrEqual:
        return '>=';
      case RuleOperator.lessOrEqual:
        return '<=';
      case RuleOperator.notEquals:
        return '!=';
    }
  }

  bool evaluateCondition(double currentValue) {
    switch (operator) {
      case RuleOperator.greaterThan:
        return currentValue > thresholdValue;
      case RuleOperator.lessThan:
        return currentValue < thresholdValue;
      case RuleOperator.equals:
        return currentValue == thresholdValue;
      case RuleOperator.greaterOrEqual:
        return currentValue >= thresholdValue;
      case RuleOperator.lessOrEqual:
        return currentValue <= thresholdValue;
      case RuleOperator.notEquals:
        return currentValue != thresholdValue;
    }
  }

  RuleConfig copyWith({
    String? name,
    bool? isActive,
    String? sourceWidgetId,
    RuleOperator? operator,
    double? thresholdValue,
    List<RuleAction>? actions,
    DateTime? lastTriggeredAt,
    int? triggerCount,
    String? dashboardId,
  }) {
    return RuleConfig(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      sourceWidgetId: sourceWidgetId ?? this.sourceWidgetId,
      operator: operator ?? this.operator,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      actions: actions ?? this.actions,
      createdAt: createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      triggerCount: triggerCount ?? this.triggerCount,
      dashboardId: dashboardId ?? this.dashboardId,
    );
  }
}
