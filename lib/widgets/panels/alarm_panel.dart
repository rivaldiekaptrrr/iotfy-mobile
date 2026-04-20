import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/alarm_event.dart';
import '../../providers/alarm_providers.dart';
import '../../screens/alarm_detail_screen.dart';

class AlarmPanel extends ConsumerWidget {
  final PanelWidgetConfig config;

  const AlarmPanel({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state to trigger rebuild when alarms change
    final allAlarms = ref.watch(alarmEventsProvider);

    // Filter active alarms and limit to 3
    final alarms = allAlarms.where((a) => a.isActive).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final displayAlarms = alarms.take(3).toList();

    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: scheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Alarms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Show buttons if there's any alarm (active or cleared)
                if (allAlarms.isNotEmpty) ...[
                  // Details button always shows if there's alarm history
                  TextButton(
                    onPressed: () => _openDetail(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      allAlarms.length > displayAlarms.length
                          ? 'History (${allAlarms.length})'
                          : 'Details',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Alarm List
          Expanded(
            child: displayAlarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No Active Alarms',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if (allAlarms.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap "History" to view past alarms',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: displayAlarms.length,
                    itemBuilder: (context, index) =>
                        AlarmEventCard(alarm: displayAlarms[index]),
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlarmDetailScreen()),
    );
  }
}

class AlarmEventCard extends StatefulWidget {
  final AlarmEvent alarm;
  const AlarmEventCard({super.key, required this.alarm});

  @override
  State<AlarmEventCard> createState() => _AlarmEventCardState();
}

class _AlarmEventCardState extends State<AlarmEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Only pulse if critical/major and NOT acknowledged
    if ((widget.alarm.severity == AlarmSeverity.critical ||
            widget.alarm.severity == AlarmSeverity.major) &&
        widget.alarm.status != AlarmStatus.acknowledged) {
      _controller.repeat(reverse: true);
    }

    _animation = Tween<double>(begin: 1.0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final alarm = widget.alarm;
    // Helper methods must be accessed via context or static/mixin if they were in the parent
    // But since I'm extracting this, I'll duplicate the logic or we need to pass props.
    // To minimize refactor, I will embed the logic.

    final severityColor = _getSeverityColor(alarm.severity);
    final severityIcon = _getSeverityIcon(alarm.severity);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Pulse opacity of border or background
        final pulseOpacity = _controller.isAnimating ? _animation.value : 1.0;

        return Hero(
          tag: 'alarm_${alarm.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alarm.status == AlarmStatus.acknowledged
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: alarm.status == AlarmStatus.acknowledged
                      ? scheme.outline.withValues(alpha: 0.3)
                      : severityColor.withValues(alpha: 
                          0.5 * pulseOpacity,
                        ), // Pulse the border alpha
                  width: 1.5,
                ),
                boxShadow: _controller.isAnimating
                    ? [
                        BoxShadow(
                          color: severityColor.withValues(alpha: 0.2 * pulseOpacity),
                          blurRadius: 8 * pulseOpacity,
                        ),
                      ]
                    : [],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(severityIcon, color: severityColor, size: 16),
              const SizedBox(width: 6),
              Text(
                alarm.severity.name.toUpperCase(),
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(alarm.startTime),
                style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            alarm.sensorName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Duration: ${alarm.durationString}',
                style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              if (alarm.status == AlarmStatus.acknowledged)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'ACK',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
