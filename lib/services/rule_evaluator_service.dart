import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../models/mqtt_message.dart';
import '../models/panel_widget_config.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../providers/rule_providers.dart';
import '../services/mqtt_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RuleEvaluatorService {
  final Ref ref;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  // Track last values to avoid repeated triggers
  final Map<String, double> _lastValues = {};
  final Map<String, DateTime> _lastTriggerTimes = {};

  RuleEvaluatorService(this.ref) : _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    _initNotifications();
    _startListening();
  }

  Future<void> _initNotifications() async {
    const initializationSettingsWindows = DarwinInitializationSettings();
    const initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open notification');
    const initializationSettings = InitializationSettings(
      linux: initializationSettingsLinux,
      macOS: initializationSettingsWindows,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
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
    
    // Find widget that subscribes to this topic
    final sourceWidget = dashboard.widgets.firstWhere(
      (w) => w.subscribeTopic == message.topic,
      orElse: () => PanelWidgetConfig(title: '', type: WidgetType.text, x: 0, y: 0),
    );
    
    if (sourceWidget.subscribeTopic == null) return;

    // Try to parse value as double
    final value = double.tryParse(message.payload);
    if (value == null) return;

    // Evaluate rules for this widget
    for (final rule in rules.where((r) => r.sourceWidgetId == sourceWidget.id)) {
      _evaluateRule(rule, value, sourceWidget);
    }
  }

  void _evaluateRule(RuleConfig rule, double currentValue, PanelWidgetConfig sourceWidget) {
    // Check if condition is met
    if (!rule.evaluateCondition(currentValue)) return;

    // Debounce: Don't trigger same rule too frequently (30 second cooldown)
    final lastTrigger = _lastTriggerTimes[rule.id];
    if (lastTrigger != null && DateTime.now().difference(lastTrigger).inSeconds < 30) {
      return;
    }

    // Check if value actually changed significantly
    final lastValue = _lastValues[rule.id];
    if (lastValue != null && (lastValue - currentValue).abs() < 0.1) {
      return; // Value hasn't changed enough
    }

    // Trigger actions
    _executeActions(rule, currentValue, sourceWidget);

    // Record trigger
    ref.read(ruleConfigsProvider.notifier).recordTrigger(rule.id);
    _lastTriggerTimes[rule.id] = DateTime.now();
    _lastValues[rule.id] = currentValue;
  }

  void _executeActions(RuleConfig rule, double currentValue, PanelWidgetConfig sourceWidget) {
    for (final action in rule.actions) {
      switch (action.type) {
        case RuleActionType.publishMqtt:
          _publishMqtt(action);
          break;
        case RuleActionType.showNotification:
          _showNotification(action, rule, currentValue, sourceWidget);
          break;
        case RuleActionType.showInAppAlert:
          // This would require context, so we'll use notification instead for now
          _showNotification(action, rule, currentValue, sourceWidget);
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

  Future<void> _showNotification(RuleAction action, RuleConfig rule, double value, PanelWidgetConfig widget) async {
    const notificationDetails = NotificationDetails(
      linux: LinuxNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final title = action.notificationTitle ?? '🔔 ${rule.name}';
    final body = action.notificationBody ?? 
      '${widget.title}: ${value.toStringAsFixed(1)} ${widget.unit ?? ''}\n'
      'Condition: ${rule.getOperatorSymbol()} ${rule.thresholdValue}';

    await _notificationsPlugin.show(
      rule.hashCode, // Use rule hash as notification ID
      title,
      body,
      notificationDetails,
    );
  }

  void _logToHistory(RuleConfig rule, double value, PanelWidgetConfig widget) {
    // TODO: Implement history logging to Hive or file
    print('[RULE LOG] ${DateTime.now()}: ${rule.name} triggered - ${widget.title} = $value');
  }
}

final ruleEvaluatorProvider = Provider<RuleEvaluatorService>((ref) {
  return RuleEvaluatorService(ref);
});
