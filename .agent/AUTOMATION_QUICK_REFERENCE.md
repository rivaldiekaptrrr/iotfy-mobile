# 🚀 Automation System - Quick Reference Guide

## 📐 Data Model Architecture

### **3 Trigger Types**
```dart
RuleTriggerType.widgetValue  // Sensor-based (e.g., temp > 30)
RuleTriggerType.manual       // User clicks button
RuleTriggerType.schedule     // Time-based (daily, weekly, etc.)
```

### **4 Schedule Types**
```dart
ScheduleType.once      // Run once at specific DateTime
ScheduleType.daily     // Every day at HH:MM
ScheduleType.weekly    // Specific weekdays at HH:MM
ScheduleType.interval  // Every N minutes
```

### **5 Action Types**
```dart
RuleActionType.publishMqtt       // Publish MQTT message
RuleActionType.showNotification  // System notification
RuleActionType.showInAppAlert    // In-app dialog
RuleActionType.logToHistory      // Console log
RuleActionType.controlWidget     // ⭐ Control another widget
```

---

## 🎯 Creating Rules

### **Widget-Based Rule**
```dart
RuleConfig(
  name: "Fan Auto-On",
  dashboardId: "dash-123",
  triggerType: RuleTriggerType.widgetValue,
  sourceWidgetId: "widget-temp",
  operator: RuleOperator.greaterThan,
  thresholdValue: 30.0,
  actions: [
    RuleAction(
      type: RuleActionType.controlWidget,
      targetWidgetId: "widget-fan-toggle",
      targetPayload: "ON",
    ),
  ],
)
```

### **Manual Trigger Rule**
```dart
RuleConfig(
  name: "Panic Button",
  dashboardId: "dash-123",
  triggerType: RuleTriggerType.manual,
  actions: [
    RuleAction(
      type: RuleActionType.publishMqtt,
      mqttTopic: "security/alert",
      mqttPayload: "PANIC",
    ),
  ],
)
```

### **Daily Schedule Rule**
```dart
RuleConfig(
  name: "Morning Routine",
  dashboardId: "dash-123",
  triggerType: RuleTriggerType.schedule,
  scheduleConfig: ScheduleConfig(
    type: ScheduleType.daily,
    dailyTimeMinutes: 420, // 07:00
  ),
  actions: [
    RuleAction(
      type: RuleActionType.controlWidget,
      targetWidgetId: "lights-main",
      targetPayload: "ON",
    ),
  ],
)
```

---

## ⏰ Time Conversion

```dart
// TimeOfDay → Minutes
final minutes = ScheduleConfig.timeOfDayToMinutes(TimeOfDay(hour: 14, minute: 30));
// Result: 870

// Minutes → TimeOfDay
final time = ScheduleConfig.minutesToTimeOfDay(870);
// Result: TimeOfDay(14:30)

// Using getters
final config = ScheduleConfig(
  type: ScheduleType.daily,
  dailyTimeMinutes: 870,
);
print(config.dailyTime); // TimeOfDay(14:30)
```

---

## 🔍 Helper Methods

### **Check Trigger Type**
```dart
if (rule.canTriggerManually) {
  // Show "Trigger" button
}

if (rule.hasSchedule) {
  // Show schedule info
}
```

### **Get Description**
```dart
final description = rule.getTriggerDescription();
// Examples:
// "Widget Condition"
// "Manual Trigger"
// "Daily at 08:00"
// "Weekly (Mon, Wed, Fri) at 14:30"
// "Every 30m"
```

---

## 📋 Validation Rules

```dart
// ✅ Valid Widget Rule
RuleConfig(
  triggerType: RuleTriggerType.widgetValue,
  sourceWidgetId: "widget-1", // ✅ Required
  operator: RuleOperator.greaterThan, // ✅ Required
  thresholdValue: 50.0, // ✅ Required
)

// ✅ Valid Manual Rule
RuleConfig(
  triggerType: RuleTriggerType.manual,
  // sourceWidgetId not required
  // operator not required
  // thresholdValue not required
)

// ✅ Valid Schedule Rule
RuleConfig(
  triggerType: RuleTriggerType.schedule,
  scheduleConfig: ScheduleConfig(...), // ✅ Required
)

// ❌ Invalid - will throw assertion
RuleConfig(
  triggerType: RuleTriggerType.widgetValue,
  // Missing: sourceWidgetId, operator, thresholdValue
)
```

---

## 🎨 UI Integration

### **Display Rule Trigger**
```dart
// In Card/List
Text(rule.getTriggerDescription())

// Check if manual
if (rule.canTriggerManually) {
  IconButton(
    icon: Icon(Icons.play_arrow),
    onPressed: () => triggerRuleManually(rule.id),
  )
}
```

### **Action Icons**
```dart
IconData getActionIcon(RuleActionType type) {
  switch (type) {
    case RuleActionType.controlWidget: return Icons.widgets;
    case RuleActionType.publishMqtt: return Icons.publish;
    case RuleActionType.showNotification: return Icons.notifications;
    // ...
  }
}
```

---

## 🗂️ Hive Type IDs Reference

| ID | Type | Usage |
|----|------|-------|
| 4 | RuleOperator | <, >, ==, etc. |
| 5 | RuleActionType | Actions enum |
| 6 | RuleAction | Action config |
| 7 | RuleConfig | Main rule |
| **8** | **RuleTriggerType** | **⭐ NEW** |
| **9** | **ScheduleType** | **⭐ NEW** |
| **10** | **ScheduleConfig** | **⭐ NEW** |

---

## 🐛 Common Pitfalls

### ❌ Don't use TimeOfDay directly in Hive
```dart
@HiveField(0) final TimeOfDay time; // ❌ NOT SERIALIZABLE
```

### ✅ Use minutes instead
```dart
@HiveField(0) final int timeMinutes; // ✅ WORKS
TimeOfDay get time => ScheduleConfig.minutesToTimeOfDay(timeMinutes);
```

### ❌ Don't forget nullable checks
```dart
final threshold = rule.thresholdValue; // ❌ Can be null now
```

### ✅ Use null-aware operators
```dart
final threshold = rule.thresholdValue ?? 0; // ✅ Safe
```

---

## 📚 Further Reading

- Full documentation: `.agent/AUTOMATION_SYSTEM_PHASE1_SUMMARY.md`
- Implementation plan: See conversation history
- Next phase: Phase 2 - Service Layer Implementation

---

**Last Updated**: 2026-01-28  
**Phase**: 1 (Data Model)  
**Status**: ✅ Complete
