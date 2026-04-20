
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class SliderPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const SliderPanel({super.key, required this.config});

  @override
  ConsumerState<SliderPanel> createState() => _SliderPanelState();
}

class _SliderPanelState extends ConsumerState<SliderPanel> {
  double _currentValue = 0;
  bool _isDragging = false;
  
  late final ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>> _messageSub;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.config.minValue ?? 0;
    _subscribeToTopic();
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (!_isDragging && message.topic == widget.config.subscribeTopic) {
            final val = double.tryParse(message.payload);
            if (val != null) {
              setState(() {
                _currentValue = val.clamp(
                  widget.config.minValue ?? 0, 
                  widget.config.maxValue ?? 100
                );
              });
            }
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

    final minValue = widget.config.minValue ?? 0;
    final maxValue = widget.config.maxValue ?? 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minDimension = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        
        // Responsive scaling
        final titleSize = (minDimension * 0.1).clamp(12.0, 24.0);
        final valueSize = (minDimension * 0.15).clamp(16.0, 36.0);
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.config.title,
                  style: TextStyle(
                    fontSize: titleSize, 
                    fontWeight: FontWeight.w500
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: minDimension * 0.05),
                Text(
                  '${_currentValue.round()} ${widget.config.unit ?? ''}',
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: widget.config.color,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: widget.config.color,
                      inactiveTrackColor: widget.config.color.withValues(alpha: 0.2),
                      thumbColor: widget.config.color,
                      overlayColor: widget.config.color.withValues(alpha: 0.1),
                      trackHeight: 4.0 + (minDimension * 0.01), // Responsive track thickness
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0 + (minDimension * 0.01)),
                    ),
                    child: Slider(
                      value: _currentValue,
                      min: minValue,
                      max: maxValue,
                      divisions: (maxValue - minValue).toInt() > 0 ? (maxValue - minValue).toInt() : 1, 
                      onChanged: (value) {
                         setState(() {
                           _currentValue = value.roundToDouble(); // Snap to integer
                           _isDragging = true;
                         });
                      },
                      onChangeEnd: (value) {
                        setState(() {
                          _isDragging = false;
                        });
                        if (!isConnected) {
                           _showConnectionWarning(context, lastError);
                           // Reset or keep? Let's keep visually but it won't sync if sub
                           return;
                        }
                        _publishValue(value.roundToDouble());
                      },
                    ),
                  ),
                ),
                if (!isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isError ? Colors.red : Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isError ? 'Error' : 'Offline',
                      style: TextStyle(color: isError ? Colors.red : Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _publishValue(double value) {
    if (widget.config.publishTopic == null) return;
    
    final service = ref.read(mqttServiceProvider);
    String payload;

    if (widget.config.isJsonPayload && widget.config.jsonPattern != null) {
      // Use JSON Pattern
      String result = widget.config.jsonPattern!;
      result = result.replaceAll('<value>', value.round().toString());
      result = result.replaceAll('<slider-payload>', value.round().toString());
      result = result.replaceAll('<timestamp>', DateTime.now().millisecondsSinceEpoch.toString());
      result = result.replaceAll('<iso-timestamp>', DateTime.now().toIso8601String());
      payload = result;
    } else {
      // Plain value
      payload = value.round().toString();
    }

    service.publish(
      widget.config.publishTopic!,
      payload,
      qos: widget.config.qos,
    );
  }

  void _showConnectionWarning(BuildContext context, String? lastError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lastError != null ? 'Failed to publish: $lastError' : 'MQTT Disconnected'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
