import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../models/mqtt_message.dart';
import '../models/panel_widget_config.dart';
import '../models/alarm_event.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../providers/rule_providers.dart';
import '../providers/alarm_providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/rule_activity_provider.dart';

class RuleEvaluatorService {
  final Ref ref;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  // Track last values to avoid repeated triggers
  final Map<String, double> _lastValues = {};
  final Map<String, DateTime> _lastTriggerTimes = {};

  RuleEvaluatorService(this.ref)
    : _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    _initNotifications();
    _startListening();
  }

  Future<void> _initNotifications() async {
    try {
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsLinux = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      const initializationSettingsDarwin = DarwinInitializationSettings();

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        linux: initializationSettingsLinux,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(initializationSettings);
      debugPrint('[NOTIFICATION] Initialized successfully');
    } catch (e) {
      debugPrint('[NOTIFICATION] Init failed (platform may not support): $e');
    }
  }

  void _startListening() {
    debugPrint('[RULE SERVICE] Starting to listen for MQTT messages...');

    // Listen to MQTT messages
    ref.listen<AsyncValue<MqttMessageData>>(mqttMessagesProvider, (
      previous,
      next,
    ) {
      next.whenData((message) {
        debugPrint(
          '[RULE SERVICE] 📨 Received MQTT: topic=${message.topic}, payload=${message.payload}',
        );
        _evaluateRulesForMessage(message);
      });
    });

    debugPrint('[RULE SERVICE] ✅ Listener registered');
  }

  void _evaluateRulesForMessage(MqttMessageData message) {
    debugPrint('[RULE EVAL] ===== Message Received =====');
    debugPrint('[RULE EVAL] Topic: ${message.topic}');
    debugPrint('[RULE EVAL] Payload: ${message.payload}');

    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) {
      debugPrint('[RULE EVAL] ❌ No dashboard, skipping');
      return;
    }

    debugPrint('[RULE EVAL] Dashboard: ${dashboard.name}');

    // Get active rules for current dashboard
    final rules = ref
        .read(ruleConfigsProvider.notifier)
        .getActiveRulesForDashboard(dashboard.id);

    debugPrint('[RULE EVAL] Active rules count: ${rules.length}');

    if (rules.isEmpty) {
      debugPrint('[RULE EVAL] ⚠️ No active rules, skipping');
      return;
    }

    // Find widget that subscribes to this topic
    final sourceWidgets = dashboard.widgets.where(
      (w) => w.subscribeTopic == message.topic,
    );

    debugPrint(
      '[RULE EVAL] Widgets subscribed to this topic: ${sourceWidgets.length}',
    );

    if (sourceWidgets.isEmpty) {
      debugPrint('[RULE EVAL] ⚠️ No widget subscribes to topic: ${message.topic}');
      return;
    }

    // Try to parse value as double
    final payloadClean = message.payload.trim();
    final value = double.tryParse(payloadClean);

    if (value == null) {
      debugPrint('[RULE EVAL] ❌ Failed to parse payload as double: "$payloadClean"');
      return;
    }

    debugPrint('[RULE EVAL] ✅ Parsed value: $value');

    for (final widget in sourceWidgets) {
      debugPrint('[RULE EVAL] Checking widget: ${widget.title} (${widget.id})');

      // Get all rules for this widget (widgetValue OR manual)
      final widgetRules = rules
          .where(
            (r) =>
                (r.triggerType == RuleTriggerType.widgetValue ||
                    r.triggerType == RuleTriggerType.manual) &&
                r.sourceWidgetId == widget.id,
          )
          .toList();

      debugPrint('[RULE EVAL] Rules for this widget: ${widgetRules.length}');

      if (widgetRules.isNotEmpty) {
        for (final rule in widgetRules) {
          debugPrint(
            '[RULE EVAL] 🔍 Found rule: ${rule.name} (${rule.triggerType})',
          );

          // For manual triggers: execute immediately on any state change
          if (rule.triggerType == RuleTriggerType.manual) {
            debugPrint(
              '[RULE EVAL] 👆 Manual trigger - executing without condition check',
            );
            _executeActions(rule, value, widget);
            ref.read(ruleConfigsProvider.notifier).recordTrigger(rule.id);
          } else {
            // For widgetValue triggers: evaluate condition
            _evaluateRule(rule, value, widget);
          }
        }
      }
    }
  }

  void triggerRuleManually(String ruleId) {
    final rule = ref.read(ruleConfigsProvider.notifier).getRule(ruleId);
    if (rule == null || !rule.isActive) return;

    debugPrint('[RULE] Manually triggering rule: ${rule.name}');
    _executeActions(rule, null, null);

    // Record trigger
    ref.read(ruleConfigsProvider.notifier).recordTrigger(rule.id);
  }

  void _evaluateRule(
    RuleConfig rule,
    double currentValue,
    PanelWidgetConfig sourceWidget,
  ) {
    debugPrint('[EVAL] ===== Evaluating Rule: ${rule.name} =====');
    debugPrint('[EVAL] Current Value: $currentValue');
    debugPrint('[EVAL] Threshold: ${rule.thresholdValue}');
    debugPrint('[EVAL] Operator: ${rule.getOperatorSymbol()}');

    final alarmNotifier = ref.read(alarmEventsProvider.notifier);
    final existingAlarm = alarmNotifier.getActiveAlarmForRule(rule.id);

    // Check if condition is met
    final conditionMet = rule.evaluateCondition(currentValue);

    debugPrint(
      '[EVAL] Condition "$currentValue ${rule.getOperatorSymbol()} ${rule.thresholdValue}" = $conditionMet',
    );

    if (conditionMet) {
      debugPrint('[EVAL] ✅ Condition MET!');

      // Debounce check for alarm creation
      final lastTrigger = _lastTriggerTimes[rule.id];
      final shouldCreateAlarm =
          existingAlarm == null &&
          (lastTrigger == null ||
              DateTime.now().difference(lastTrigger).inSeconds >= 5);

      if (shouldCreateAlarm) {
        debugPrint('[EVAL] Creating new alarm...');

        // Create new alarm
        final alarm = AlarmEvent(
          ruleId: rule.id,
          ruleName: rule.name,
          sensorName: sourceWidget.title,
          severity: rule.severity,
          startTime: DateTime.now(),
          triggerValue: currentValue,
          thresholdValue: rule.thresholdValue ?? 0,
          condition: '${rule.getOperatorSymbol()} ${rule.thresholdValue ?? ""}',
        );

        alarmNotifier.addAlarm(alarm);
        debugPrint('[EVAL] ✅ Alarm created');

        // Record trigger time
        _lastTriggerTimes[rule.id] = DateTime.now();
        ref.read(ruleConfigsProvider.notifier).recordTrigger(rule.id);
      } else if (existingAlarm != null) {
        debugPrint('[EVAL] ⚠️ Alarm already exists, skipping alarm creation');
      } else {
        debugPrint(
          '[EVAL] ⏱️ Alarm debounced (will create in ${5 - DateTime.now().difference(lastTrigger!).inSeconds}s)',
        );
      }

      // IMPORTANT: Execute actions ALWAYS when condition is met
      // This ensures control widget actions run every time, not just on alarm creation
      debugPrint('[EVAL] 🚀 Executing actions (regardless of debounce)...');
      _executeActions(rule, currentValue, sourceWidget);
    } else {
      debugPrint('[EVAL] ❌ Condition NOT met');

      // Condition not met - clear alarm if exists and not acknowledged
      if (existingAlarm != null &&
          existingAlarm.status != AlarmStatus.acknowledged) {
        alarmNotifier.clearAlarm(existingAlarm.id);
        debugPrint('[EVAL] Cleared existing alarm');
      }
    }

    _lastValues[rule.id] = currentValue;
  }

  void _executeActions(
    RuleConfig rule,
    double? currentValue,
    PanelWidgetConfig? sourceWidget,
  ) {
    debugPrint(
      '[EXEC] Executing ${rule.actions.length} actions for rule: ${rule.name}',
    );

    for (final action in rule.actions) {
      debugPrint('[EXEC] Action type: ${action.type}');

      switch (action.type) {
        case RuleActionType.publishMqtt:
          _publishMqtt(action);
          break;
        case RuleActionType.showNotification:
          _showNotification(action, rule, currentValue, sourceWidget);
          break;
        case RuleActionType.showInAppAlert:
          _showNotification(action, rule, currentValue, sourceWidget);
          break;
        case RuleActionType.logToHistory:
          _logToHistory(rule, currentValue, sourceWidget);
          break;
        case RuleActionType.controlWidget:
          debugPrint('[EXEC] Calling _controlWidget...');
          _controlWidget(action);
          break;
      }
    }
  }

  void _controlWidget(RuleAction action) {
    debugPrint('[CONTROL] _controlWidget called');
    debugPrint('[CONTROL] targetWidgetId: ${action.targetWidgetId}');
    debugPrint('[CONTROL] targetPayload: ${action.targetPayload}');

    if (action.targetWidgetId == null || action.targetPayload == null) {
      debugPrint('[CONTROL] ERROR: Missing targetWidgetId or targetPayload');
      return;
    }

    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) {
      debugPrint('[CONTROL] ERROR: No dashboard found');
      return;
    }

    try {
      final targetWidget = dashboard.widgets.firstWhere(
        (w) => w.id == action.targetWidgetId,
        orElse: () => throw Exception('Target widget not found'),
      );

      debugPrint('[CONTROL] Found target widget: ${targetWidget.title}');
      debugPrint('[CONTROL] Widget publishTopic: ${targetWidget.publishTopic}');

      if (targetWidget.publishTopic != null) {
        debugPrint('[CONTROL] Publishing to topic: ${targetWidget.publishTopic}');
        debugPrint('[CONTROL] Payload: ${action.targetPayload}');

        final mqttService = ref.read(mqttServiceProvider);
        mqttService.publish(targetWidget.publishTopic!, action.targetPayload!);

        debugPrint('[CONTROL] ✅ MQTT publish successful');

        ref
            .read(ruleActivityProvider.notifier)
            .addLog(
              ruleName: 'System',
              actionDescription:
                  'Controlled ${targetWidget.title} -> ${action.targetPayload}',
            );
      } else {
        debugPrint('[CONTROL] ERROR: Widget has no publishTopic configured');
      }
    } catch (e) {
      debugPrint('[CONTROL] ERROR: Exception occurred: $e');
    }
  }

  void _publishMqtt(RuleAction action) {
    if (action.mqttTopic == null || action.mqttPayload == null) return;

    final mqttService = ref.read(mqttServiceProvider);
    mqttService.publish(action.mqttTopic!, action.mqttPayload!);

    ref
        .read(ruleActivityProvider.notifier)
        .addLog(
          ruleName: 'System',
          actionDescription:
              'Published "${action.mqttPayload}" to ${action.mqttTopic}',
        );
  }

  Future<void> _showNotification(
    RuleAction action,
    RuleConfig rule,
    double? value,
    PanelWidgetConfig? widget,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        channelDescription: 'Alarm notifications from rule engine',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const linuxDetails = LinuxNotificationDetails();
      const darwinDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final title = action.notificationTitle ?? '🔔 ${rule.name}';
      String body = action.notificationBody ?? '';

      if (body.isEmpty) {
        if (widget != null && value != null) {
          body =
              '${widget.title}: ${value.toStringAsFixed(1)} ${widget.unit ?? ''}\n'
              'Condition: ${rule.getOperatorSymbol()} ${rule.thresholdValue}';
        } else {
          body = 'Rule triggered: ${rule.name}';
        }
      }

      await _notificationsPlugin.show(
        rule.hashCode,
        title,
        body,
        notificationDetails,
      );

      debugPrint('[NOTIFICATION] Sent: $title');
      ref
          .read(ruleActivityProvider.notifier)
          .addLog(
            ruleName: rule.name,
            actionDescription: 'Notification sent: "$title"',
          );
    } catch (e) {
      debugPrint('[NOTIFICATION] Show failed: $e');
      ref
          .read(ruleActivityProvider.notifier)
          .addLog(
            ruleName: rule.name,
            actionDescription: 'Notification failed: $e',
          );
    }
  }

  void _logToHistory(
    RuleConfig rule,
    double? value,
    PanelWidgetConfig? widget,
  ) {
    final contextInfo = widget != null && value != null
        ? ' - ${widget.title} = $value'
        : '';
    final message = 'Triggered$contextInfo';

    debugPrint('[RULE LOG] ${DateTime.now()}: ${rule.name} $message');

    // Log to activity provider
    ref
        .read(ruleActivityProvider.notifier)
        .addLog(ruleName: rule.name, actionDescription: message);
  }
}

final ruleEvaluatorProvider = Provider<RuleEvaluatorService>((ref) {
  return RuleEvaluatorService(ref);
});
