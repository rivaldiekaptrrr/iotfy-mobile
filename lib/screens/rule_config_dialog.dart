import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../models/panel_widget_config.dart';
import '../models/alarm_event.dart';
import '../providers/rule_providers.dart';
import '../providers/storage_providers.dart';

class RuleConfigDialog extends ConsumerStatefulWidget {
  final String dashboardId;
  final RuleConfig? initialRule;

  const RuleConfigDialog({
    super.key,
    required this.dashboardId,
    this.initialRule,
  });

  @override
  ConsumerState<RuleConfigDialog> createState() => _RuleConfigDialogState();
}

class _RuleConfigDialogState extends ConsumerState<RuleConfigDialog> {
  late TextEditingController _nameController;
  late TextEditingController _thresholdController;
  late TextEditingController _notifyTitleController;
  late TextEditingController _notifyBodyController;
  late TextEditingController _mqttTopicController;
  late TextEditingController _mqttPayloadController;

  String? _selectedWidgetId;
  RuleOperator _selectedOperator = RuleOperator.greaterThan;
  AlarmSeverity _selectedSeverity = AlarmSeverity.minor;

  bool _enableNotification = true;
  bool _enableMqttPublish = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialRule?.name ?? '',
    );
    _thresholdController = TextEditingController(
      text: widget.initialRule?.thresholdValue.toString() ?? '0',
    );
    _notifyTitleController = TextEditingController(
      text:
          widget.initialRule?.actions
              .where((a) => a.type == RuleActionType.showNotification)
              .firstOrNull
              ?.notificationTitle ??
          '',
    );
    _notifyBodyController = TextEditingController();
    _mqttTopicController = TextEditingController();
    _mqttPayloadController = TextEditingController();

    if (widget.initialRule != null) {
      _selectedWidgetId = widget.initialRule!.sourceWidgetId;
      _selectedOperator = widget.initialRule!.operator;
      _selectedSeverity = widget.initialRule!.severity;

      _enableNotification = widget.initialRule!.actions.any(
        (a) => a.type == RuleActionType.showNotification,
      );
      _enableMqttPublish = widget.initialRule!.actions.any(
        (a) => a.type == RuleActionType.publishMqtt,
      );

      final mqttAction = widget.initialRule!.actions
          .where((a) => a.type == RuleActionType.publishMqtt)
          .firstOrNull;
      if (mqttAction != null) {
        _mqttTopicController.text = mqttAction.mqttTopic ?? '';
        _mqttPayloadController.text = mqttAction.mqttPayload ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    _notifyTitleController.dispose();
    _notifyBodyController.dispose();
    _mqttTopicController.dispose();
    _mqttPayloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(currentDashboardProvider)!;
    final widgets = dashboard.widgets
        .where(
          (w) =>
              w.type == WidgetType.gauge ||
              w.type == WidgetType.slider ||
              w.subscribeTopic != null,
        )
        .toList();

    return AlertDialog(
      title: Text(widget.initialRule == null ? 'Add Rule' : 'Edit Rule'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Rule Name',
                  hintText: 'e.g. High Temperature Alert',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Condition:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedWidgetId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Source Widget',
                  border: OutlineInputBorder(),
                ),
                items: widgets
                    .map(
                      (w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedWidgetId = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RuleOperator>(
                      value: _selectedOperator,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Operator',
                        border: OutlineInputBorder(),
                      ),
                      items: RuleOperator.values
                          .map(
                            (op) => DropdownMenuItem(
                              value: op,
                              child: Text(
                                _getOperatorText(op),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedOperator = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _thresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Threshold Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AlarmSeverity>(
                value: _selectedSeverity,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Alarm Severity',
                  border: OutlineInputBorder(),
                ),
                items: AlarmSeverity.values
                    .map(
                      (severity) => DropdownMenuItem(
                        value: severity,
                        child: Row(
                          children: [
                            Icon(
                              _getSeverityIcon(severity),
                              size: 16,
                              color: _getSeverityColor(severity),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                severity.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSeverity = value!);
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Show Notification'),
                value: _enableNotification,
                onChanged: (value) {
                  setState(() => _enableNotification = value!);
                },
              ),
              if (_enableNotification) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: TextField(
                    controller: _notifyTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      hintText: 'e.g. ⚠️ High Temperature',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
              CheckboxListTile(
                title: const Text('Publish MQTT Message'),
                value: _enableMqttPublish,
                onChanged: (value) {
                  setState(() => _enableMqttPublish = value!);
                },
              ),
              if (_enableMqttPublish) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _mqttTopicController,
                        decoration: const InputDecoration(
                          labelText: 'MQTT Topic',
                          hintText: 'e.g. fan/control',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mqttPayloadController,
                        decoration: const InputDecoration(
                          labelText: 'MQTT Payload',
                          hintText: 'e.g. ON',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveRule, child: const Text('Save')),
      ],
    );
  }

  String _getOperatorText(RuleOperator op) {
    switch (op) {
      case RuleOperator.greaterThan:
        return '(>)';
      case RuleOperator.lessThan:
        return '(<)';
      case RuleOperator.equals:
        return '(==)';
      case RuleOperator.greaterOrEqual:
        return '(>=)';
      case RuleOperator.lessOrEqual:
        return '(<=)';
      case RuleOperator.notEquals:
        return '(!=)';
    }
  }

  void _saveRule() {
    if (_nameController.text.isEmpty || _selectedWidgetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final threshold = double.tryParse(_thresholdController.text);
    if (threshold == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid threshold value')));
      return;
    }

    // Build actions list
    final actions = <RuleAction>[];

    if (_enableNotification) {
      actions.add(
        RuleAction(
          type: RuleActionType.showNotification,
          notificationTitle: _notifyTitleController.text.isEmpty
              ? _nameController.text
              : _notifyTitleController.text,
        ),
      );
    }

    if (_enableMqttPublish &&
        _mqttTopicController.text.isNotEmpty &&
        _mqttPayloadController.text.isNotEmpty) {
      actions.add(
        RuleAction(
          type: RuleActionType.publishMqtt,
          mqttTopic: _mqttTopicController.text,
          mqttPayload: _mqttPayloadController.text,
        ),
      );
    }

    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable at least one action')),
      );
      return;
    }

    final rule = RuleConfig(
      id: widget.initialRule?.id,
      name: _nameController.text,
      sourceWidgetId: _selectedWidgetId!,
      operator: _selectedOperator,
      thresholdValue: threshold,
      actions: actions,
      dashboardId: widget.dashboardId,
      severity: _selectedSeverity,
      isActive: widget.initialRule?.isActive ?? true,
      createdAt: widget.initialRule?.createdAt,
      triggerCount: widget.initialRule?.triggerCount ?? 0,
      lastTriggeredAt: widget.initialRule?.lastTriggeredAt,
    );

    if (widget.initialRule == null) {
      ref.read(ruleConfigsProvider.notifier).addRule(rule);
    } else {
      ref.read(ruleConfigsProvider.notifier).updateRule(rule);
    }

    Navigator.pop(context);
  }

  Color _getSeverityColor(AlarmSeverity severity) {
    switch (severity) {
      case AlarmSeverity.critical:
        return Colors.red;
      case AlarmSeverity.major:
        return Colors.orange;
      case AlarmSeverity.minor:
        return Colors.yellow.shade700;
    }
  }

  IconData _getSeverityIcon(AlarmSeverity severity) {
    switch (severity) {
      case AlarmSeverity.critical:
        return Icons.error;
      case AlarmSeverity.major:
        return Icons.warning;
      case AlarmSeverity.minor:
        return Icons.info;
    }
  }
}
