import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../providers/rule_providers.dart';
import '../providers/storage_providers.dart';
import 'rule_config_dialog.dart';

class RuleManagerScreen extends ConsumerWidget {
  const RuleManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(currentDashboardProvider);
    final allRules = ref.watch(ruleConfigsProvider);
    
    if (dashboard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rule Engine')),
        body: const Center(child: Text('No active dashboard')),
      );
    }

    final rules = allRules.where((r) => r.dashboardId == dashboard.id).toList();
    final activeRules = rules.where((r) => r.isActive).toList();
    final inactiveRules = rules.where((r) => !r.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: rules.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeRules.isNotEmpty) ...[
                  _buildSectionHeader(context, '✅ ACTIVE', activeRules.length, Colors.green),
                  const SizedBox(height: 12),
                  ...activeRules.map((rule) => _buildRuleCard(context, ref, rule)),
                  const SizedBox(height: 24),
                ],
                if (inactiveRules.isNotEmpty) ...[
                  _buildSectionHeader(context, '⚪ INACTIVE', inactiveRules.length, Colors.grey),
                  const SizedBox(height: 12),
                  ...inactiveRules.map((rule) => _buildRuleCard(context, ref, rule)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewRule(context, ref, dashboard.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
          const SizedBox(height: 8),
          const Text('Create rules to automate your dashboard'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border:Border.all(color: color.withOpacity(0.3)),
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
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, WidgetRef ref, RuleConfig rule) {
    final dashboard = ref.read(currentDashboardProvider)!;
    final widget = dashboard.widgets.firstWhere(
      (w) => w.id == rule.sourceWidgetId,
      orElse: () => dashboard.widgets.first,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Switch(
                  value: rule.isActive,
                  onChanged: (_) {
                    ref.read(ruleConfigsProvider.notifier).toggleRuleActive(rule.id);
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
                  Row(
                    children: [
                      const Text('IF ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        widget.title,
                        style: TextStyle(color: widget.color, fontWeight: FontWeight.w600),
                      ),
                      Text(' ${rule.getOperatorSymbol()} '),
                      Text(
                        '${rule.thresholdValue} ${widget.unit ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('THEN:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...rule.actions.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        Icon(_getActionIcon(action.type), size: 14),
                        const SizedBox(width: 4),
                        Text(_getActionText(action)),
                      ],
                    ),
                  )),
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
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editRule(context, ref, rule),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteRule(context, ref, rule),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    }
  }

  String _getActionText(RuleAction action) {
    switch (action.type) {
      case RuleActionType.publishMqtt:
        return 'Publish "${action.mqttPayload}" to ${action.mqttTopic}';
      case RuleActionType.showNotification:
        return 'Show notification: "${action.notificationTitle}"';
      case RuleActionType.showInAppAlert:
        return 'Show in-app alert';
      case RuleActionType.logToHistory:
        return 'Log to history';
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

  void _addNewRule(BuildContext context, WidgetRef ref, String dashboardId) {
    showDialog(
      context: context,
      builder: (_) => RuleConfigDialog(dashboardId: dashboardId),
    );
  }

  void _editRule(BuildContext context, WidgetRef ref, RuleConfig rule) {
    showDialog(
      context: context,
      builder: (_) => RuleConfigDialog(
        dashboardId: rule.dashboardId,
        initialRule: rule,
      ),
    );
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rule Engine Help'),
        content: const SingleChildScrollView(
          child: Text(
            'Create automation rules to trigger actions when conditions are met.\n\n'
            'Examples:\n'
            '• IF Temperature > 30°C THEN Turn on fan\n'
            '• IF Humidity < 20% THEN Send notification\n\n'
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
