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
  final RuleConfig? templateRule;

  const RuleConfigDialog({
    super.key,
    required this.dashboardId,
    this.initialRule,
    this.templateRule,
  });

  @override
  ConsumerState<RuleConfigDialog> createState() => _RuleConfigDialogState();
}

class _RuleConfigDialogState extends ConsumerState<RuleConfigDialog> {
  late TextEditingController _nameController;
  late TextEditingController _thresholdController;
  late TextEditingController _notifyTitleController;
  late TextEditingController _mqttTopicController;
  late TextEditingController _mqttPayloadController;

  // Trigger configuration
  RuleTriggerType _triggerType = RuleTriggerType.widgetValue;
  String? _selectedWidgetId;
  RuleOperator _selectedOperator = RuleOperator.greaterThan;

  // Schedule configuration
  ScheduleType _scheduleType = ScheduleType.daily;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime? _onceDateTime;
  Set<int> _selectedWeekdays = {1, 2, 3, 4, 5}; // Mon-Fri
  int _intervalMinutes = 30;

  // Actions
  AlarmSeverity _selectedSeverity = AlarmSeverity.minor;
  bool _enableNotification = true;
  bool _enableMqttPublish = false;
  bool _enableControlWidget = false;
  String? _targetWidgetId;
  late TextEditingController _targetPayloadController;

  @override
  void initState() {
    super.initState();

    final sourceRule = widget.initialRule ?? widget.templateRule;

    _nameController = TextEditingController(text: sourceRule?.name ?? '');
    _thresholdController = TextEditingController(
      text: sourceRule?.thresholdValue?.toString() ?? '0',
    );
    _notifyTitleController = TextEditingController(
      text:
          sourceRule?.actions
              .where((a) => a.type == RuleActionType.showNotification)
              .firstOrNull
              ?.notificationTitle ??
          '',
    );
    _mqttTopicController = TextEditingController();
    _mqttPayloadController = TextEditingController();
    _targetPayloadController = TextEditingController(text: 'ON');

    if (sourceRule != null) {
      _triggerType = sourceRule.triggerType;
      _selectedWidgetId = sourceRule.sourceWidgetId;
      _selectedOperator = sourceRule.operator ?? RuleOperator.greaterThan;
      _selectedSeverity = sourceRule.severity;

      // Load schedule config
      if (sourceRule.scheduleConfig != null) {
        final config = sourceRule.scheduleConfig!;
        _scheduleType = config.type;
        if (config.dailyTime != null) _selectedTime = config.dailyTime!;
        if (config.weeklyTime != null) _selectedTime = config.weeklyTime!;
        if (config.weekdays != null) {
          _selectedWeekdays = config.weekdays!.toSet();
        }
        if (config.intervalMinutes != null) {
          _intervalMinutes = config.intervalMinutes!;
        }
        if (config.executeAt != null) _onceDateTime = config.executeAt;
      }

      // Load actions
      _enableNotification = sourceRule.actions.any(
        (a) => a.type == RuleActionType.showNotification,
      );
      _enableMqttPublish = sourceRule.actions.any(
        (a) => a.type == RuleActionType.publishMqtt,
      );
      _enableControlWidget = sourceRule.actions.any(
        (a) => a.type == RuleActionType.controlWidget,
      );

      final mqttAction = sourceRule.actions
          .where((a) => a.type == RuleActionType.publishMqtt)
          .firstOrNull;
      if (mqttAction != null) {
        _mqttTopicController.text = mqttAction.mqttTopic ?? '';
        _mqttPayloadController.text = mqttAction.mqttPayload ?? '';
      }

      final controlAction = sourceRule.actions
          .where((a) => a.type == RuleActionType.controlWidget)
          .firstOrNull;
      if (controlAction != null) {
        _targetWidgetId = controlAction.targetWidgetId;
        _targetPayloadController.text = controlAction.targetPayload ?? 'ON';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    _notifyTitleController.dispose();
    _mqttTopicController.dispose();
    _mqttPayloadController.dispose();
    _targetPayloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(currentDashboardProvider)!;

    // Source widgets (for condition)
    final sourceWidgets = dashboard.widgets
        .where(
          (w) =>
              w.type == WidgetType.gauge ||
              w.type == WidgetType.lineChart ||
              w.type == WidgetType.kpiCard ||
              w.type == WidgetType.radialGauge ||
              w.type == WidgetType.battery ||
              w.type == WidgetType.liquidTank,
        )
        .toList();

    // Target widgets (for control action)
    final targetWidgets = dashboard.widgets
        .where(
          (w) =>
              w.type == WidgetType.toggle ||
              w.type == WidgetType.button ||
              w.type == WidgetType.slider ||
              w.type == WidgetType.knob,
        )
        .toList();

    return AlertDialog(
      title: Text(
        widget.initialRule == null ? 'Add Automation Rule' : 'Edit Rule',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rule Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Rule Name',
                  hintText: 'e.g., Turn on fan when hot',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Trigger Type Selector
              const Text(
                'Trigger Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<RuleTriggerType>(
                segments: const [
                  ButtonSegment(
                    value: RuleTriggerType.widgetValue,
                    label: Text('Widget'),
                    icon: Icon(Icons.sensors, size: 16),
                  ),
                  ButtonSegment(
                    value: RuleTriggerType.schedule,
                    label: Text('Schedule'),
                    icon: Icon(Icons.schedule, size: 16),
                  ),
                ],
                selected: {_triggerType},
                onSelectionChanged: (Set<RuleTriggerType> newSelection) {
                  setState(() {
                    _triggerType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Conditional UI based on trigger type
              if (_triggerType == RuleTriggerType.widgetValue) ...[
                _buildWidgetConditionUI(sourceWidgets),
              ] else if (_triggerType == RuleTriggerType.schedule) ...[
                _buildScheduleUI(),
              ],

              const Divider(height: 32),

              // Actions Section
              const Text(
                'Actions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Control Widget Action
              CheckboxListTile(
                title: const Text('Control Another Widget'),
                subtitle: const Text('Automatically control another widget'),
                value: _enableControlWidget,
                onChanged: (val) =>
                    setState(() => _enableControlWidget = val ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              if (_enableControlWidget) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _targetWidgetId,
                  decoration: const InputDecoration(
                    labelText: 'Target Widget',
                    border: OutlineInputBorder(),
                  ),
                  items: targetWidgets.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Row(
                        children: [
                          Icon(
                            w.type == WidgetType.toggle
                                ? Icons.toggle_on
                                : Icons.widgets,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(w.title),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _targetWidgetId = val),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetPayloadController,
                  decoration: const InputDecoration(
                    labelText: 'Payload to Send',
                    hintText: 'ON, OFF, 50, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notification Action
              CheckboxListTile(
                title: const Text('Show Notification'),
                value: _enableNotification,
                onChanged: (val) =>
                    setState(() => _enableNotification = val ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              if (_enableNotification) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _notifyTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // MQTT Publish Action
              CheckboxListTile(
                title: const Text('Publish MQTT Message'),
                value: _enableMqttPublish,
                onChanged: (val) =>
                    setState(() => _enableMqttPublish = val ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              if (_enableMqttPublish) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _mqttTopicController,
                  decoration: const InputDecoration(
                    labelText: 'MQTT Topic',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mqttPayloadController,
                  decoration: const InputDecoration(
                    labelText: 'MQTT Payload',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Severity
              const Text(
                'Severity:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AlarmSeverity>(
                segments: const [
                  ButtonSegment(
                    value: AlarmSeverity.minor,
                    label: Text('Minor'),
                  ),
                  ButtonSegment(
                    value: AlarmSeverity.major,
                    label: Text('Major'),
                  ),
                  ButtonSegment(
                    value: AlarmSeverity.critical,
                    label: Text('Critical'),
                  ),
                ],
                selected: {_selectedSeverity},
                onSelectionChanged: (Set<AlarmSeverity> newSelection) {
                  setState(() => _selectedSeverity = newSelection.first);
                },
              ),
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

  Widget _buildWidgetConditionUI(List<PanelWidgetConfig> sourceWidgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IF Condition:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedWidgetId,
          decoration: const InputDecoration(
            labelText: 'Source Widget',
            border: OutlineInputBorder(),
          ),
          items: sourceWidgets.map((w) {
            return DropdownMenuItem(
              value: w.id,
              child: Text('${w.title} (${w.unit ?? 'value'})'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedWidgetId = val),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<RuleOperator>(
                initialValue: _selectedOperator,
                decoration: const InputDecoration(
                  labelText: 'Operator',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: RuleOperator.greaterThan,
                    child: Text('> Greater'),
                  ),
                  DropdownMenuItem(
                    value: RuleOperator.lessThan,
                    child: Text('< Less'),
                  ),
                  DropdownMenuItem(
                    value: RuleOperator.equals,
                    child: Text('== Equal'),
                  ),
                  DropdownMenuItem(
                    value: RuleOperator.greaterOrEqual,
                    child: Text('>= Greater or Equal'),
                  ),
                  DropdownMenuItem(
                    value: RuleOperator.lessOrEqual,
                    child: Text('<= Less or Equal'),
                  ),
                  DropdownMenuItem(
                    value: RuleOperator.notEquals,
                    child: Text('!= Not Equal'),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedOperator = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Type:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ScheduleType>(
          segments: const [
            ButtonSegment(value: ScheduleType.once, label: Text('Once')),
            ButtonSegment(value: ScheduleType.daily, label: Text('Daily')),
            ButtonSegment(value: ScheduleType.weekly, label: Text('Weekly')),
            ButtonSegment(
              value: ScheduleType.interval,
              label: Text('Interval'),
            ),
          ],
          selected: {_scheduleType},
          onSelectionChanged: (Set<ScheduleType> newSelection) {
            setState(() => _scheduleType = newSelection.first);
          },
        ),
        const SizedBox(height: 16),

        if (_scheduleType == ScheduleType.once) ...[
          ListTile(
            title: Text(
              _onceDateTime == null
                  ? 'Select Date & Time'
                  : 'Execute at: ${_onceDateTime!.toString().substring(0, 16)}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _onceDateTime ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    _onceDateTime ?? DateTime.now(),
                  ),
                );
                if (time != null && mounted) {
                  setState(() {
                    _onceDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ] else if (_scheduleType == ScheduleType.daily) ...[
          ListTile(
            title: Text('Time: ${_selectedTime.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ] else if (_scheduleType == ScheduleType.weekly) ...[
          ListTile(
            title: Text('Time: ${_selectedTime.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          const Text('Days:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (int day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1],
                  ),
                  selected: _selectedWeekdays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedWeekdays.add(day);
                      } else {
                        _selectedWeekdays.remove(day);
                      }
                    });
                  },
                ),
            ],
          ),
        ] else if (_scheduleType == ScheduleType.interval) ...[
          TextField(
            decoration: const InputDecoration(
              labelText: 'Interval (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _intervalMinutes.toString(),
            ),
            onChanged: (val) {
              _intervalMinutes = int.tryParse(val) ?? 30;
            },
          ),
        ],
      ],
    );
  }

  void _saveRule() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a rule name')));
      return;
    }

    // Validate based on trigger type
    if (_triggerType == RuleTriggerType.widgetValue &&
        _selectedWidgetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source widget')),
      );
      return;
    }

    if (_triggerType == RuleTriggerType.schedule &&
        _scheduleType == ScheduleType.once &&
        _onceDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select execution date and time')),
      );
      return;
    }

    // Build actions list
    final actions = <RuleAction>[];

    if (_enableControlWidget && _targetWidgetId != null) {
      actions.add(
        RuleAction(
          type: RuleActionType.controlWidget,
          targetWidgetId: _targetWidgetId,
          targetPayload: _targetPayloadController.text,
        ),
      );
    }

    if (_enableNotification) {
      actions.add(
        RuleAction(
          type: RuleActionType.showNotification,
          notificationTitle: _notifyTitleController.text.isEmpty
              ? null
              : _notifyTitleController.text,
        ),
      );
    }

    if (_enableMqttPublish) {
      actions.add(
        RuleAction(
          type: RuleActionType.publishMqtt,
          mqttTopic: _mqttTopicController.text,
          mqttPayload: _mqttPayloadController.text,
        ),
      );
    }

    // Always add log action
    actions.add(const RuleAction(type: RuleActionType.logToHistory));

    // Build schedule config
    ScheduleConfig? scheduleConfig;
    if (_triggerType == RuleTriggerType.schedule) {
      switch (_scheduleType) {
        case ScheduleType.once:
          scheduleConfig = ScheduleConfig(
            type: ScheduleType.once,
            executeAt: _onceDateTime,
          );
          break;
        case ScheduleType.daily:
          scheduleConfig = ScheduleConfig(
            type: ScheduleType.daily,
            dailyTimeMinutes: ScheduleConfig.timeOfDayToMinutes(_selectedTime),
          );
          break;
        case ScheduleType.weekly:
          scheduleConfig = ScheduleConfig(
            type: ScheduleType.weekly,
            weekdays: _selectedWeekdays.toList()..sort(),
            weeklyTimeMinutes: ScheduleConfig.timeOfDayToMinutes(_selectedTime),
          );
          break;
        case ScheduleType.interval:
          scheduleConfig = ScheduleConfig(
            type: ScheduleType.interval,
            intervalMinutes: _intervalMinutes,
          );
          break;
      }
    }

    final rule = RuleConfig(
      id: widget.initialRule?.id,
      name: _nameController.text,
      dashboardId: widget.dashboardId,
      triggerType: _triggerType,
      sourceWidgetId: _triggerType == RuleTriggerType.widgetValue
          ? _selectedWidgetId
          : null,
      operator: _triggerType == RuleTriggerType.widgetValue
          ? _selectedOperator
          : null,
      thresholdValue: _triggerType == RuleTriggerType.widgetValue
          ? double.tryParse(_thresholdController.text) ?? 0
          : null,
      scheduleConfig: scheduleConfig,
      actions: actions,
      severity: _selectedSeverity,
      createdAt: widget.initialRule?.createdAt,
      lastTriggeredAt: widget.initialRule?.lastTriggeredAt,
      triggerCount: widget.initialRule?.triggerCount ?? 0,
    );

    if (widget.initialRule == null) {
      ref.read(ruleConfigsProvider.notifier).addRule(rule);
    } else {
      ref.read(ruleConfigsProvider.notifier).updateRule(rule);
    }

    Navigator.pop(context);
  }
}
