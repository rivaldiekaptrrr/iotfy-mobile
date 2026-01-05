import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_event.dart';
import '../providers/alarm_providers.dart';

class AlarmDetailScreen extends ConsumerWidget {
  const AlarmDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state to trigger rebuild when alarms change
    final allAlarms = ref.watch(alarmEventsProvider);

    // Sort and limit to 10
    final alarms = allAlarms.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final displayAlarms = alarms.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Details'),
        actions: [
          if (allAlarms.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All History',
              onPressed: () => _showResetConfirmation(context, ref),
            ),
        ],
      ),
      body: displayAlarms.isEmpty
          ? const Center(child: Text('No alarms'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayAlarms.length,
              itemBuilder: (context, index) =>
                  _buildAlarmCard(context, ref, displayAlarms[index]),
            ),
    );
  }

  Widget _buildAlarmCard(
    BuildContext context,
    WidgetRef ref,
    AlarmEvent alarm,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final severityColor = _getSeverityColor(alarm.severity);

    return Hero(
      tag: 'alarm_${alarm.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getSeverityIcon(alarm.severity),
                    color: severityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    alarm.severity.name.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (alarm.status != AlarmStatus.cleared &&
                      alarm.status != AlarmStatus.acknowledged)
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(alarmEventsProvider.notifier)
                          .acknowledgeAlarm(alarm.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('ACK', style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                    )
                  else if (alarm.status == AlarmStatus.acknowledged)
                    Chip(
                      label: const Text(
                        'ACKNOWLEDGED',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.blue),
                    )
                  else
                    Chip(
                      label: const Text(
                        'CLEARED',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.green.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alarm.sensorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Start Time', _formatDateTime(alarm.startTime)),
              if (alarm.endTime != null)
                _buildInfoRow('End Time', _formatDateTime(alarm.endTime!)),
              _buildInfoRow('Duration', alarm.durationString),
              _buildInfoRow('Condition', alarm.condition),
              _buildInfoRow(
                'Trigger Value',
                '${alarm.triggerValue.toStringAsFixed(1)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
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

  String _formatDateTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all alarm records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(alarmEventsProvider.notifier).clearAllAlarms();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All history cleared')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
