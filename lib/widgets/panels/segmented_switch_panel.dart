import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class SegmentedSwitchPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const SegmentedSwitchPanel({super.key, required this.config});

  @override
  ConsumerState<SegmentedSwitchPanel> createState() => _SegmentedSwitchPanelState();
}

class _SegmentedSwitchPanelState extends ConsumerState<SegmentedSwitchPanel> {
  int _selectedIndex = -1;
  late final List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = widget.config.options != null && widget.config.options!.isNotEmpty
        ? widget.config.options!
        : ['Low', 'Med', 'High'];
  }

  void _publish(int index) {
    if (widget.config.publishTopic != null) {
      final val = _options[index];
      ref.read(mqttServiceProvider).publish(
        widget.config.publishTopic!, 
        val,
        retain: widget.config.qos == 1 || widget.config.qos == 2
      );
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.config.title,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // If width is limited, might need to wrap or scroll, but segmented switch usually single row.
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_options.length, (index) {
                        final isSelected = _selectedIndex == index;
                        return Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _publish(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isSelected 
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] 
                                  : null,
                              ),
                              child: Text(
                                _options[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
