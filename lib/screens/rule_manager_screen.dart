import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/rule_config.dart';
import '../models/panel_widget_config.dart';
import '../providers/rule_providers.dart';
import '../providers/storage_providers.dart';
import '../providers/rule_activity_provider.dart';
import '../services/rule_evaluator_service.dart';
import 'rule_config_dialog.dart';

class RuleManagerScreen extends ConsumerWidget {
  const RuleManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(currentDashboardProvider);

    if (dashboard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rule Engine')),
        body: const Center(child: Text('No active dashboard')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Automation Rules'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.rule), text: 'Rules'),
              Tab(icon: Icon(Icons.history), text: 'Activity Log'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _RulesTab(dashboardId: dashboard.id),
            const _ActivityLogTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addNewRule(context, ref, dashboard.id),
          icon: const Icon(Icons.add),
          label: const Text('Add Rule'),
        ),
      ),
    );
  }

  void _addNewRule(BuildContext context, WidgetRef ref, String dashboardId) {
    showDialog(
      context: context,
      builder: (_) => RuleConfigDialog(dashboardId: dashboardId),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Automation Rules Help'),
        content: const SingleChildScrollView(
          child: Text(
            'Create powerful automation rules with three trigger types:\n\n'
            '📊 WIDGET TRIGGER\n'
            'Trigger based on sensor values (e.g., IF temperature > 30°C)\n\n'
            '👆 MANUAL TRIGGER\n'
            'Execute rules on-demand with a button click\n\n'
            '⏰ SCHEDULE TRIGGER\n'
            'Run rules at specific times (daily, weekly, intervals)\n\n'
            'ACTIONS:\n'
            '• Control other widgets (turn on/off, set values)\n'
            '• Send MQTT messages\n'
            '• Show notifications\n'
            '• Log events\n\n'
            'Rules run automatically in the background while the app is open.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _RulesTab extends ConsumerWidget {
  final String dashboardId;

  const _RulesTab({required this.dashboardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRules = ref.watch(ruleConfigsProvider);
    final dashboard = ref.watch(
      currentDashboardProvider,
    ); // Need dashboard for widgets lookup
    final rules = allRules.where((r) => r.dashboardId == dashboardId).toList();
    final activeRules = rules.where((r) => r.isActive).toList();
    final inactiveRules = rules.where((r) => !r.isActive).toList();

    if (rules.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeRules.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            '✅ ACTIVE',
            activeRules.length,
            Colors.green,
          ),
          const SizedBox(height: 12),
          ...activeRules.map(
            (rule) => _RuleCard(rule: rule, dashboard: dashboard),
          ),
          const SizedBox(height: 24),
        ],
        if (inactiveRules.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            '⚪ INACTIVE',
            inactiveRules.length,
            Colors.grey,
          ),
          const SizedBox(height: 12),
          ...inactiveRules.map(
            (rule) => _RuleCard(rule: rule, dashboard: dashboard),
          ),
        ],
        const SizedBox(height: 60), // Space for FAB
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'No automation rules yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start with a template:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildTemplateButton(
                  context,
                  Icons.notifications_active,
                  'Value Alert',
                  Colors.blue,
                  RuleConfig(
                    name: 'High Value Alert',
                    dashboardId: dashboardId,
                    triggerType: RuleTriggerType.widgetValue,
                    operator: RuleOperator.greaterThan,
                    thresholdValue: 80,
                    actions: [
                      RuleAction(
                        type: RuleActionType.showNotification,
                        notificationTitle: 'Value Alert',
                      ),
                    ],
                  ),
                ),
                _buildTemplateButton(
                  context,
                  Icons.schedule,
                  'Daily 8AM',
                  Colors.purple,
                  RuleConfig(
                    name: 'Morning Task',
                    dashboardId: dashboardId,
                    triggerType: RuleTriggerType.schedule,
                    scheduleConfig: ScheduleConfig(
                      type: ScheduleType.daily,
                      dailyTimeMinutes: 480,
                    ),
                    actions: [RuleAction(type: RuleActionType.logToHistory)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    RuleConfig template,
  ) {
    return FilledButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) =>
            RuleConfigDialog(dashboardId: dashboardId, templateRule: template),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends ConsumerWidget {
  final RuleConfig rule;
  final dynamic
  dashboard; // Using dynamic to avoid excessive type imports if not needed, or better pass Widgets list

  const _RuleCard({required this.rule, required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find source widget (may be null for manual/schedule triggers)
    PanelWidgetConfig? sourceWidget;
    if (rule.sourceWidgetId != null && dashboard != null) {
      try {
        sourceWidget = dashboard.widgets.firstWhere(
          (w) => w.id == rule.sourceWidgetId,
        );
      } catch (e) {
        // Widget not found
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _editRule(context, rule),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    rule.isActive ? Icons.check_circle : Icons.cancel,
                    color: rule.isActive ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _TriggerBadge(type: rule.triggerType),
                  const SizedBox(width: 8),
                  Switch(
                    value: rule.isActive,
                    onChanged: (_) {
                      ref
                          .read(ruleConfigsProvider.notifier)
                          .toggleRuleActive(rule.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trigger description
                    Row(
                      children: [
                        Icon(
                          _getTriggerIcon(rule.triggerType),
                          size: 16,
                          color: _getTriggerColor(rule.triggerType),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _buildTriggerDescription(rule, sourceWidget),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'THEN:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...rule.actions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            Icon(_getActionIcon(action.type), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(_getActionText(action, dashboard)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (rule.lastTriggeredAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last triggered: ${_formatTime(rule.lastTriggeredAt!)} (${rule.triggerCount}x)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Test/Manual Trigger Button
                  if (rule.isActive)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilledButton.icon(
                        onPressed: () => _triggerRule(context, ref, rule),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Test'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ),

                  // Context Menu for Edit/Duplicate/Delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editRule(context, rule);
                          break;
                        case 'duplicate':
                          _duplicateRule(ref, rule);
                          break;
                        case 'delete':
                          _deleteRule(context, ref, rule);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerRule(BuildContext context, WidgetRef ref, RuleConfig rule) {
    ref.read(ruleEvaluatorProvider).triggerRuleManually(rule.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rule "${rule.name}" triggered!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editRule(BuildContext context, RuleConfig rule) {
    showDialog(
      context: context,
      builder: (_) =>
          RuleConfigDialog(dashboardId: rule.dashboardId, initialRule: rule),
    );
  }

  void _duplicateRule(WidgetRef ref, RuleConfig rule) {
    final newRule = RuleConfig(
      id: const Uuid().v4(),
      name: '${rule.name} (Copy)',
      dashboardId: rule.dashboardId,
      triggerType: rule.triggerType,
      sourceWidgetId: rule.sourceWidgetId,
      operator: rule.operator,
      thresholdValue: rule.thresholdValue,
      scheduleConfig: rule.scheduleConfig,
      actions: rule.actions,
      severity: rule.severity,
      // Default new state
      isActive: false,
      triggerCount: 0,
      createdAt: DateTime.now(),
    );

    ref.read(ruleConfigsProvider.notifier).addRule(newRule);
  }

  void _deleteRule(BuildContext context, WidgetRef ref, RuleConfig rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: Text('Are you sure you want to delete "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(ruleConfigsProvider.notifier).deleteRule(rule.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helpers
  Color _getTriggerColor(RuleTriggerType type) {
    switch (type) {
      case RuleTriggerType.schedule:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getTriggerIcon(RuleTriggerType type) {
    switch (type) {
      case RuleTriggerType.schedule:
        return Icons.schedule;
      default:
        return Icons.sensors;
    }
  }

  String _buildTriggerDescription(
    RuleConfig rule,
    PanelWidgetConfig? sourceWidget,
  ) {
    if (rule.triggerType == RuleTriggerType.schedule) {
      return 'SCHEDULE: ${rule.getTriggerDescription()}';
    }

    if (sourceWidget != null) {
      return 'IF ${sourceWidget.title} ${rule.getOperatorSymbol()} ${rule.thresholdValue ?? ''} ${sourceWidget.unit ?? ''}';
    }
    return 'IF [Widget not found]';
  }

  IconData _getActionIcon(RuleActionType type) {
    switch (type) {
      case RuleActionType.publishMqtt:
        return Icons.publish;
      case RuleActionType.showNotification:
        return Icons.notifications;
      case RuleActionType.showInAppAlert:
        return Icons.warning;
      case RuleActionType.logToHistory:
        return Icons.history;
      case RuleActionType.controlWidget:
        return Icons.widgets;
    }
  }

  String _getActionText(RuleAction action, dynamic dashboard) {
    switch (action.type) {
      case RuleActionType.publishMqtt:
        return 'Publish "${action.mqttPayload}" to ${action.mqttTopic}';
      case RuleActionType.showNotification:
        return 'Notify: "${action.notificationTitle ?? 'Alert'}"';
      case RuleActionType.showInAppAlert:
        return 'Show Alert';
      case RuleActionType.logToHistory:
        return 'Log';
      case RuleActionType.controlWidget:
        String widgetName = 'unknown';
        if (action.targetWidgetId != null && dashboard != null) {
          try {
            final widget = dashboard.widgets.firstWhere(
              (w) => w.id == action.targetWidgetId,
            );
            widgetName = widget.title;
          } catch (e) {}
        }
        return 'Set "$widgetName" → ${action.targetPayload}';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TriggerBadge extends StatelessWidget {
  final RuleTriggerType type;

  const _TriggerBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (type) {
      case RuleTriggerType.schedule:
        color = Colors.purple;
        label = 'SCHEDULE';
        icon = Icons.schedule;
        break;
      default:
        color = Colors.blue;
        label = 'WIDGET';
        icon = Icons.sensors;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLogTab extends ConsumerWidget {
  const _ActivityLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(ruleActivityProvider);

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: log.isSuccess
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            child: Icon(
              log.isSuccess ? Icons.check : Icons.error,
              color: log.isSuccess ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          title: Text(
            log.ruleName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.actionDescription),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, HH:mm:ss').format(log.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (log.errorMessage != null)
                Text(
                  log.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }
}
