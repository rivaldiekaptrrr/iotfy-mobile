import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class GaugePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const GaugePanel({super.key, required this.config});

  @override
  ConsumerState<GaugePanel> createState() => _GaugePanelState();
}

class _GaugePanelState extends ConsumerState<GaugePanel> {
  double _currentValue = 0;
  String? _error;
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>> _messageSub;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            _updateValue(message.payload);
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
    final isConnected = connectionStatus.value == ConnectionStatus.connected;
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.read(mqttServiceProvider).lastError;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              Text(
                isError ? 'MQTT error' : 'Disconnected',
                style: TextStyle(color: isError ? Colors.orange : Colors.red, fontSize: 12),
              )
            else
              Expanded(
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: widget.config.minValue ?? 0,
                      maximum: widget.config.maxValue ?? 100,
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: widget.config.minValue ?? 0,
                          endValue: widget.config.maxValue ?? 100,
                          color: widget.config.color.withOpacity(0.3),
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: _currentValue,
                          needleColor: widget.config.color,
                          enableAnimation: true,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Text(
                            '${_currentValue.toStringAsFixed(1)}${widget.config.unit ?? ''}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0.5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (isError && lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  lastError,
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Updated ${_lastUpdated!.toLocal().toIso8601String().substring(11, 19)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateValue(String payload) {
    try {
      final value = double.parse(payload);
      setState(() {
        _currentValue = value.clamp(
          widget.config.minValue ?? 0,
          widget.config.maxValue ?? 100,
        );
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid data';
      });
    }
  }
}