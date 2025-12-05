import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class LineChartPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const LineChartPanel({super.key, required this.config});

  @override
  ConsumerState<LineChartPanel> createState() => _LineChartPanelState();
}

class _LineChartPanelState extends ConsumerState<LineChartPanel> {
  final List<FlSpot> _dataPoints = [];
  String? _error;
  int _xCounter = 0;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
  }

  void _subscribeToTopic() {
    if (widget.config.subscribeTopic != null) {
      final service = ref.read(mqttServiceProvider);
      service.subscribe(widget.config.subscribeTopic!, qos: widget.config.qos);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<app_mqtt.MqttMessageData>>(mqttMessagesProvider, (_, next) {
      next.whenData((message) {
        if (message.topic == widget.config.subscribeTopic) {
          _addDataPoint(message.payload);
        }
      });
    });

    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.config.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              )
            else if (!isConnected)
              const Text(
                'Disconnected',
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _dataPoints.isEmpty
                  ? const Center(child: Text('Waiting for data...'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 42,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        minX: _dataPoints.isEmpty ? 0 : _dataPoints.first.x,
                        maxX: _dataPoints.isEmpty ? 10 : _dataPoints.last.x,
                        minY: widget.config.minValue ?? 0,
                        maxY: widget.config.maxValue ?? 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _dataPoints,
                            isCurved: true,
                            color: widget.config.color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: widget.config.color.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDataPoint(String payload) {
    try {
      final value = double.parse(payload);
      setState(() {
        _dataPoints.add(FlSpot(_xCounter.toDouble(), value));
        _xCounter++;

        final maxPoints = widget.config.maxDataPoints ?? 50;
        if (_dataPoints.length > maxPoints) {
          _dataPoints.removeAt(0);
        }

        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid data';
      });
    }
  }
}