import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class KPIPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const KPIPanel({super.key, required this.config});

  @override
  ConsumerState<KPIPanel> createState() => _KPIPanelState();
}

class _KPIPanelState extends ConsumerState<KPIPanel>
    with SingleTickerProviderStateMixin {
  final List<FlSpot> _dataPoints = [];
  int _xCounter = 0;
  String? _lastPayload;
  double? _lastValue;
  double? _previousValue; // To calculate trend
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>>
  _messageSub;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      final value = double.parse(payload);

      setState(() {
        if (_lastValue != null) {
          _previousValue = _lastValue;
        }
        _lastValue = value;
        _lastPayload = payload;

        _dataPoints.add(FlSpot(_xCounter.toDouble(), value));
        _xCounter++;

        // Keep last 20 points for sparkline
        if (_dataPoints.length > 20) {
          _dataPoints.removeAt(0);
        }
      });
    } catch (e) {
      setState(() {
        _lastPayload = payload; // Display as string if not a number
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _messageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.config.color;
    final isLoading = _lastValue == null && _lastPayload == null;

    // Calculate Trend
    IconData? trendIcon;
    Color? trendColor;
    if (_lastValue != null && _previousValue != null) {
      if (_lastValue! > _previousValue!) {
        trendIcon = Icons.arrow_upward;
        trendColor = Colors.green;
      } else if (_lastValue! < _previousValue!) {
        trendIcon = Icons.arrow_downward;
        trendColor = Colors.red;
      }
    }

    return ClipRRect(
      child: Stack(
        children: [
          // Sparkline Background
          if (_dataPoints.length > 2)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20), // Push down slightly
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: _dataPoints.first.x,
                      maxX: _dataPoints.last.x,
                      minY: _dataPoints
                          .map((e) => e.y)
                          .reduce((a, b) => a < b ? a : b),
                      maxY: _dataPoints
                          .map((e) => e.y)
                          .reduce((a, b) => a > b ? a : b),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.config.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.config.icon != null)
                      Icon(widget.config.icon, color: color.withOpacity(0.7)),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: isLoading
                          ? _buildShimmer(
                              width: 80,
                              height: 32,
                              baseColor: theme.disabledColor.withOpacity(0.3),
                              highlightColor: theme.disabledColor.withOpacity(
                                0.1,
                              ),
                            )
                          : TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: _previousValue ?? 0,
                                end: _lastValue ?? 0,
                              ),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Text(
                                  _lastValue != null
                                      ? value.toStringAsFixed(widget.config.decimalPlaces)
                                      : _lastPayload ?? '-',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                    ),
                    if (widget.config.unit != null &&
                        widget.config.unit!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          widget.config.unit!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (trendIcon != null)
                  Row(
                    children: [
                      Icon(trendIcon, size: 16, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        'vs last update',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({
    required double width,
    required double height,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.3, 0.4],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              tileMode: TileMode.clamp,
              transform: GradientRotation(
                _shimmerController.value * 2 * 3.14159,
              ), // Rotate/Move gradient
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
