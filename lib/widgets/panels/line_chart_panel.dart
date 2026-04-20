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
  // ignore: unused_field
  String? _error;
  int _xCounter = 0;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>> _messageSub;
  double? _lastValue;
  // ignore: unused_field
  DateTime? _lastUpdated;
  String? _currentValueDisplay;

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

  @override
  void dispose() {
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.read(mqttServiceProvider).lastError;
    final scheme = Theme.of(context).colorScheme;

    Color lineColor = widget.config.color;
    if (_lastValue != null) {
      if (widget.config.criticalThreshold != null && _lastValue! >= widget.config.criticalThreshold!) {
        lineColor = Colors.red;
      } else if (widget.config.warningThreshold != null && _lastValue! >= widget.config.warningThreshold!) {
        lineColor = Colors.orange;
      }
    }

    // Simplified without Card wrapper as it is handled by PanelContainer
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 180),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Expanded(
                   child: Text(
                    widget.config.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                 ),
                if (_currentValueDisplay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: lineColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentValueDisplay!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: lineColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _dataPoints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, size: 32, color: scheme.outline.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for data...',
                            style: TextStyle(color: scheme.outline),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: ((widget.config.maxValue ?? 100) - (widget.config.minValue ?? 0)) / 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: scheme.outlineVariant.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        minX: _dataPoints.isNotEmpty ? _dataPoints.first.x : 0,
                        maxX: _dataPoints.isNotEmpty ? _dataPoints.last.x : 10,
                        minY: widget.config.minValue ?? 0,
                        maxY: widget.config.maxValue ?? 100,
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            if (widget.config.warningThreshold != null)
                              HorizontalLine(
                                y: widget.config.warningThreshold!,
                                color: Colors.orange.withValues(alpha: 0.8),
                                strokeWidth: 1,
                                dashArray: [10, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                                  style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                  labelResolver: (line) => 'Warning', 
                                ),
                              ),
                            if (widget.config.criticalThreshold != null)
                              HorizontalLine(
                                y: widget.config.criticalThreshold!,
                                color: Colors.red.withValues(alpha: 0.8),
                                strokeWidth: 1,
                                dashArray: [10, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  labelResolver: (line) => 'Critical',
                                ),
                              ),
                          ],
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _dataPoints,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: lineColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  lineColor.withValues(alpha: 0.3),
                                  lineColor.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                             getTooltipColor: (_) => scheme.surfaceContainerHighest,
                             tooltipRoundedRadius: 8,
                             getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    spot.y.toStringAsFixed(widget.config.decimalPlaces),
                                    TextStyle(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                             }
                          ),
                        ),
                      ),
                    ),
            ),
            if (isError && lastError != null)
               Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      lastError,
                      style: const TextStyle(color: Colors.orange, fontSize: 10),
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
      var value = double.parse(payload);
      if (widget.config.minValue != null && widget.config.maxValue != null) {
        value = value.clamp(widget.config.minValue!, widget.config.maxValue!);
      }
      setState(() {
        _dataPoints.add(FlSpot(_xCounter.toDouble(), value));
        _xCounter++;

        final maxPoints = widget.config.maxDataPoints ?? 50;
        if (_dataPoints.length > maxPoints) {
          _dataPoints.removeAt(0);
        }

        _error = null;
        _lastValue = value;
        _lastUpdated = DateTime.now();
        _currentValueDisplay = value.toStringAsFixed(widget.config.decimalPlaces);
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid data';
      });
    }
  }
}