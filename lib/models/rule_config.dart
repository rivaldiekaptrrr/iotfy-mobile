import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'alarm_event.dart';

part 'rule_config.g.dart';

// ==================== TRIGGER TYPES ====================

@HiveType(typeId: 11)
enum RuleTriggerType {
  @HiveField(0)
  widgetValue, // Trigger dari nilai widget (existing behavior)
  @HiveField(1)
  manual, // Trigger manual by user click
  @HiveField(2)
  schedule, // Trigger berdasarkan waktu/schedule
}

@HiveType(typeId: 12)
enum ScheduleType {
  @HiveField(0)
  once, // Execute once at specific datetime
  @HiveField(1)
  daily, // Execute daily at specific time
  @HiveField(2)
  weekly, // Execute on specific weekdays at specific time
  @HiveField(3)
  interval, // Execute every N minutes/hours
}

@HiveType(typeId: 13)
class ScheduleConfig {
  @HiveField(0)
  final ScheduleType type;
  @HiveField(1)
  final DateTime? executeAt; // For 'once' type
  @HiveField(2)
  final int? dailyTimeMinutes; // For 'daily' - minutes from midnight (0-1439)
  @HiveField(3)
  final List<int>? weekdays; // For 'weekly' - [1=Mon, 2=Tue, ..., 7=Sun]
  @HiveField(4)
  final int? intervalMinutes; // For 'interval' type
  @HiveField(5)
  final int? weeklyTimeMinutes; // For 'weekly' - minutes from midnight

  const ScheduleConfig({
    required this.type,
    this.executeAt,
    this.dailyTimeMinutes,
    this.weekdays,
    this.intervalMinutes,
    this.weeklyTimeMinutes,
  });

  // Helper: Convert TimeOfDay to minutes
  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // Helper: Convert minutes to TimeOfDay
  static TimeOfDay minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  // Getters for convenience
  TimeOfDay? get dailyTime =>
      dailyTimeMinutes != null ? minutesToTimeOfDay(dailyTimeMinutes!) : null;

  TimeOfDay? get weeklyTime =>
      weeklyTimeMinutes != null ? minutesToTimeOfDay(weeklyTimeMinutes!) : null;

  ScheduleConfig copyWith({
    ScheduleType? type,
    DateTime? executeAt,
    int? dailyTimeMinutes,
    List<int>? weekdays,
    int? intervalMinutes,
    int? weeklyTimeMinutes,
  }) {
    return ScheduleConfig(
      type: type ?? this.type,
      executeAt: executeAt ?? this.executeAt,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      weekdays: weekdays ?? this.weekdays,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      weeklyTimeMinutes: weeklyTimeMinutes ?? this.weeklyTimeMinutes,
    );
  }
}

// ==================== CONDITIONS ====================

@HiveType(typeId: 4)
enum RuleOperator {
  @HiveField(0)
  greaterThan, // >
  @HiveField(1)
  lessThan, // <
  @HiveField(2)
  equals, // ==
  @HiveField(3)
  greaterOrEqual, // >=
  @HiveField(4)
  lessOrEqual, // <=
  @HiveField(5)
  notEquals, // !=
}

// ==================== ACTIONS ====================

@HiveType(typeId: 5)
enum RuleActionType {
  @HiveField(0)
  publishMqtt,
  @HiveField(1)
  showNotification,
  @HiveField(2)
  showInAppAlert,
  @HiveField(3)
  logToHistory,
  @HiveField(4)
  controlWidget, // NEW: Control another widget in dashboard
}

@HiveType(typeId: 6)
class RuleAction {
  @HiveField(0)
  final RuleActionType type;
  @HiveField(1)
  final String? mqttTopic; // For publishMqtt
  @HiveField(2)
  final String? mqttPayload; // For publishMqtt
  @HiveField(3)
  final String? notificationTitle; // For showNotification
  @HiveField(4)
  final String? notificationBody; // For showNotification
  @HiveField(5)
  final String? targetWidgetId; // For controlWidget - ID of widget to control
  @HiveField(6)
  final String? targetPayload; // For controlWidget - Payload to send (ON/OFF/value)

  const RuleAction({
    required this.type,
    this.mqttTopic,
    this.mqttPayload,
    this.notificationTitle,
    this.notificationBody,
    this.targetWidgetId,
    this.targetPayload,
  });

  RuleAction copyWith({
    RuleActionType? type,
    String? mqttTopic,
    String? mqttPayload,
    String? notificationTitle,
    String? notificationBody,
    String? targetWidgetId,
    String? targetPayload,
  }) {
    return RuleAction(
      type: type ?? this.type,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      mqttPayload: mqttPayload ?? this.mqttPayload,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
      targetWidgetId: targetWidgetId ?? this.targetWidgetId,
      targetPayload: targetPayload ?? this.targetPayload,
    );
  }
}

// ==================== RULE CONFIGURATION ====================

@HiveType(typeId: 7)
class RuleConfig extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  bool isActive;

  // ===== TRIGGER CONFIGURATION =====
  @HiveField(12)
  RuleTriggerType triggerType; // NEW: Type of trigger
  @HiveField(13)
  ScheduleConfig? scheduleConfig; // NEW: Schedule config (only for schedule trigger)

  // ===== CONDITION (for widgetValue trigger) =====
  @HiveField(3)
  String? sourceWidgetId; // Which widget to monitor (nullable now)
  @HiveField(4)
  RuleOperator? operator; // Comparison operator (nullable for manual/schedule)
  @HiveField(5)
  double? thresholdValue; // Threshold value (nullable for manual/schedule)

  // ===== ACTIONS =====
  @HiveField(6)
  List<RuleAction> actions;

  // ===== METADATA =====
  @HiveField(7)
  DateTime createdAt;
  @HiveField(8)
  DateTime? lastTriggeredAt;
  @HiveField(9)
  int triggerCount;
  @HiveField(10)
  String dashboardId; // Which dashboard this rule belongs to
  @HiveField(11)
  AlarmSeverity severity; // Alarm severity level

  RuleConfig({
    String? id,
    required this.name,
    this.isActive = true,
    this.triggerType =
        RuleTriggerType.widgetValue, // Default: backward compatible
    this.scheduleConfig,
    this.sourceWidgetId, // Now optional
    this.operator, // Now optional
    this.thresholdValue, // Now optional
    required this.actions,
    DateTime? createdAt,
    this.lastTriggeredAt,
    this.triggerCount = 0,
    required this.dashboardId,
    this.severity = AlarmSeverity.minor,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  // Note: Validation removed to maintain backward compatibility
  // UI layer will handle validation for new rules

  String getOperatorSymbol() {
    if (operator == null) return '';

    switch (operator!) {
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
    // Only evaluate if we have valid condition config
    if (operator == null || thresholdValue == null) return false;

    switch (operator!) {
      case RuleOperator.greaterThan:
        return currentValue > thresholdValue!;
      case RuleOperator.lessThan:
        return currentValue < thresholdValue!;
      case RuleOperator.equals:
        return currentValue == thresholdValue!;
      case RuleOperator.greaterOrEqual:
        return currentValue >= thresholdValue!;
      case RuleOperator.lessOrEqual:
        return currentValue <= thresholdValue!;
      case RuleOperator.notEquals:
        return currentValue != thresholdValue!;
    }
  }

  // Helper: Check if this rule can be triggered manually
  bool get canTriggerManually => triggerType == RuleTriggerType.manual;

  // Helper: Check if this rule has schedule
  bool get hasSchedule =>
      triggerType == RuleTriggerType.schedule && scheduleConfig != null;

  // Helper: Get human-readable trigger description
  String getTriggerDescription() {
    switch (triggerType) {
      case RuleTriggerType.widgetValue:
        return sourceWidgetId != null ? 'Widget Condition' : 'Unknown';
      case RuleTriggerType.manual:
        return 'Manual Trigger';
      case RuleTriggerType.schedule:
        if (scheduleConfig == null) return 'Schedule (Not Configured)';
        switch (scheduleConfig!.type) {
          case ScheduleType.once:
            return 'Once at ${scheduleConfig!.executeAt?.toString() ?? "?"}';
          case ScheduleType.daily:
            final time = scheduleConfig!.dailyTime;
            return 'Daily at ${_formatTime(time)}';
          case ScheduleType.weekly:
            final time = scheduleConfig!.weeklyTime;
            final days =
                scheduleConfig!.weekdays?.map((d) => _dayName(d)).join(', ') ??
                '?';
            return 'Weekly ($days) at ${_formatTime(time)}';
          case ScheduleType.interval:
            final mins = scheduleConfig!.intervalMinutes ?? 0;
            return 'Every ${mins >= 60 ? '${mins ~/ 60}h' : '${mins}m'}';
        }
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '?';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return day >= 1 && day <= 7 ? days[day - 1] : '?';
  }

  RuleConfig copyWith({
    String? name,
    bool? isActive,
    RuleTriggerType? triggerType,
    ScheduleConfig? scheduleConfig,
    String? sourceWidgetId,
    RuleOperator? operator,
    double? thresholdValue,
    List<RuleAction>? actions,
    DateTime? lastTriggeredAt,
    int? triggerCount,
    String? dashboardId,
    AlarmSeverity? severity,
  }) {
    return RuleConfig(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      triggerType: triggerType ?? this.triggerType,
      scheduleConfig: scheduleConfig ?? this.scheduleConfig,
      sourceWidgetId: sourceWidgetId ?? this.sourceWidgetId,
      operator: operator ?? this.operator,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      actions: actions ?? this.actions,
      createdAt: createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      triggerCount: triggerCount ?? this.triggerCount,
      dashboardId: dashboardId ?? this.dashboardId,
      severity: severity ?? this.severity,
    );
  }
}
