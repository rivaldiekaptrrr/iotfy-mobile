import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../models/mqtt_message.dart';
import '../models/panel_widget_config.dart';
import '../models/alarm_event.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../providers/rule_providers.dart';
import '../providers/alarm_providers.dart';
import '../services/mqtt_service.dart';

class RuleEvaluatorService {
  final Ref ref;
  
  // Track last values to avoid repeated triggers
  final Map<String, double> _lastValues = {};
  final Map<String, DateTime> _lastTriggerTimes = {};

  RuleEvaluatorService(this.ref) {
    _startListening();
  }

  void _startListening() {
    // Listen to MQTT messages
    ref.listen<AsyncValue<MqttMessageData>>(mqttMessagesProvider, (previous, next) {
      next.whenData((message) {
        _evaluateRulesForMessage(message);
      });
    });
  }

  void _evaluateRulesForMessage(MqttMessageData message) {
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) return;

    // Get active rules for current dashboard
    final rules = ref.read(ruleConfigsProvider.notifier).getActiveRulesForDashboard(dashboard.id);
    if (rules.isEmpty) return; // No active rules, skip evaluation

    // Find widget that subscribes to this topic
    // Note: We need to handle potential duplicate topics or multiple widgets
    final sourceWidgets = dashboard.widgets.where((w) => w.subscribeTopic == message.topic);
    
    if (sourceWidgets.isEmpty) {
      // print('[RULE DEBUG] No widget found for topic: ${message.topic}'); // Too verbose for normal op
      return;
    }

    // Try to parse value as double
    // Trim payload to remove whitespace/newlines
    final payloadClean = message.payload.trim();
    final value = double.tryParse(payloadClean);
    if (value == null) {
      print('[RULE DEBUG] Failed to parse payload as double: "$payloadClean" (raw: "${message.payload}") for topic: ${message.topic}');
      return;
    }

    print('[RULE DEBUG] Evaluating topic: ${message.topic}, Value: $value');

    for (final widget in sourceWidgets) {
       // Evaluate rules for this widget
       final widgetRules = rules.where((r) => r.sourceWidgetId == widget.id).toList();
       
       if (widgetRules.isNotEmpty) {
         print('[RULE DEBUG] Found ${widgetRules.length} rules for widget "${widget.title}"');
       }

       for (final rule in widgetRules) {
         _evaluateRule(rule, value, widget);
       }
    }
  }

  void _evaluateRule(RuleConfig rule, double currentValue, PanelWidgetConfig sourceWidget) {
    final alarmNotifier = ref.read(alarmEventsProvider.notifier);
    final existingAlarm = alarmNotifier.getActiveAlarmForRule(rule.id);
    
    // Check if condition is met
    final conditionMet = rule.evaluateCondition(currentValue);
    
    // print('[RULE DEBUG] Rule "${rule.name}": $currentValue ${rule.getOperatorSymbol()} ${rule.thresholdValue} ? $conditionMet');
    
    if (conditionMet) {
      // Condition is met - create alarm if not exists
      if (existingAlarm == null) {
        print('[RULE DEBUG] Triggering NEW ALARM for "${rule.name}"');
        
        // Debounce check
        final lastTrigger = _lastTriggerTimes[rule.id];
        // Reduced debounce to 5s for easier testing/demo
        if (lastTrigger != null && DateTime.now().difference(lastTrigger).inSeconds < 5) {
           print('[RULE DEBUG] Debounce suppressed trigger for "${rule.name}" (last: $lastTrigger)');
           return;
        }
        
        // Create new alarm
        final alarm = AlarmEvent(
          ruleId: rule.id,
          ruleName: rule.name,
          sensorName: sourceWidget.title,
          severity: rule.severity,
          startTime: DateTime.now(),
          triggerValue: currentValue,
          thresholdValue: rule.thresholdValue,
          condition: '${rule.getOperatorSymbol()} ${rule.thresholdValue}',
        );
        
        alarmNotifier.addAlarm(alarm);
        
        // Execute actions (without system notifications)
        _executeActions(rule, currentValue, sourceWidget);
        
        // Record trigger
        ref.read(ruleConfigsProvider.notifier).recordTrigger(rule.id);
        _lastTriggerTimes[rule.id] = DateTime.now();
      }
    } else {
      // Condition not met - clear alarm if exists and not acknowledged
      if (existingAlarm != null && existingAlarm.status != AlarmStatus.acknowledged) {
        alarmNotifier.clearAlarm(existingAlarm.id);
      }
    }
    
    _lastValues[rule.id] = currentValue;
  }

  void _executeActions(RuleConfig rule, double currentValue, PanelWidgetConfig sourceWidget) {
    for (final action in rule.actions) {
      switch (action.type) {
        case RuleActionType.publishMqtt:
          _publishMqtt(action);
          break;
        case RuleActionType.showNotification:
          // System notification disabled (requires platform-specific setup)
          print('[NOTIFICATION] ${rule.name}: ${sourceWidget.title} = $currentValue');
          break;
        case RuleActionType.showInAppAlert:
          print('[ALERT] ${rule.name}: ${sourceWidget.title} = $currentValue');
          break;
        case RuleActionType.logToHistory:
          _logToHistory(rule, currentValue, sourceWidget);
          break;
      }
    }
  }

  void _publishMqtt(RuleAction action) {
    if (action.mqttTopic == null || action.mqttPayload == null) return;
    
    final mqttService = ref.read(mqttServiceProvider);
    mqttService.publish(action.mqttTopic!, action.mqttPayload!);
  }

  void _logToHistory(RuleConfig rule, double value, PanelWidgetConfig widget) {
    print('[RULE LOG] ${DateTime.now()}: ${rule.name} triggered - ${widget.title} = $value');
  }
}

final ruleEvaluatorProvider = Provider<RuleEvaluatorService>((ref) {
  return RuleEvaluatorService(ref);
});
