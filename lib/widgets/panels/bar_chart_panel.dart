import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';

class BarChartPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const BarChartPanel({super.key, required this.config});

  @override
  ConsumerState<BarChartPanel> createState() => _BarChartPanelState();
}

class _BarChartPanelState extends ConsumerState<BarChartPanel> {
  final List<BarChartGroupData> _barGroups = [];
  int _xCounter = 0;
  String? _error;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>> _messageSub;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            _addDataPoint(message.payload);
          }
        });
      },
    );
  }

  void _subscribeToTopic() {
    if (widget.config.subscribeTopic != null) {
      final service = ref.read(mqttServiceProvider);
      service.subscribe(widget.config.subscribeTopic!, qos: widget.config.qos);
    }
  }

  void _addDataPoint(String payload) {
    try {
      var value = double.parse(payload);
      if (widget.config.minValue != null && widget.config.maxValue != null) {
        value = value.clamp(widget.config.minValue!, widget.config.maxValue!);
      }

      setState(() {
        _barGroups.add(
          BarChartGroupData(
            x: _xCounter,
            barRods: [
              BarChartRodData(
                toY: value,
                color: widget.config.color,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: widget.config.maxValue ?? 100,
                  color: widget.config.color.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        );
        _xCounter++;

        // Keep limited number of bars (e.g. 10-20 to fit screen)
        // Bar charts get crowded fast.
        const maxBars = 15; 
        if (_barGroups.length > maxBars) {
          _barGroups.removeAt(0);
        }
        
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid data';
      });
    }
  }

  @override
  void dispose() {
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _barGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart, size: 32, color: scheme.outline.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for data...',
                          style: TextStyle(color: scheme.outline),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Too many labels might crowd, show every 2nd or just empty
                              return const SizedBox.shrink(); 
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: scheme.outline,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: widget.config.minValue ?? 0,
                      maxY: widget.config.maxValue ?? 100,
                      barGroups: _barGroups,
                      alignment: BarChartAlignment.spaceAround,
                    ),
                  ),
          ),
          if (_error != null)
             Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 10),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
