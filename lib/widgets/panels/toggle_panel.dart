import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';
import '../../utils/icon_helper.dart';

class TogglePanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const TogglePanel({super.key, required this.config});

  @override
  ConsumerState<TogglePanel> createState() => _TogglePanelState();
}

class _TogglePanelState extends ConsumerState<TogglePanel> {
  bool _isOn = false;
  bool _isLoading = false;
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
            setState(() {
              _isOn = message.payload.toUpperCase() == widget.config.onPayload?.toUpperCase();
              _isLoading = false;
            });
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
    final scheme = Theme.of(context).colorScheme;

    // No Card wrapper - handled by PanelContainer
    final icon = IconHelper.getIcon(widget.config.iconCodePoint);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final minDimension = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        
        // Icon size scales with widget size
        final iconSize = (minDimension * 0.25).clamp(32.0, 100.0);
        // Title font size scales - LARGER to fill card
        final titleSize = (minDimension * 0.15).clamp(14.0, 48.0);
        // Switch scale factor - LARGER to fill card
        final switchScale = (minDimension / 80).clamp(1.0, 4.0);
        
        return Center(
          child: Padding(
            padding: EdgeInsets.all(minDimension * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: iconSize,
                    color: _isOn ? widget.config.color : scheme.onSurfaceVariant,
                  ),
                if (icon != null) SizedBox(height: minDimension * 0.04),
                Text(
                  widget.config.title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: minDimension * 0.06),
                if (_isLoading)
                  SizedBox(
                    width: 24 * switchScale,
                    height: 24 * switchScale,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Transform.scale(
                    scale: switchScale,
                    child: Switch(
                      value: _isOn,
                      onChanged: (value) {
                        if (!isConnected) {
                          _showConnectionWarning(context, lastError);
                          return;
                        }
                        _toggleSwitch(value);
                      },
                      activeColor: widget.config.color,
                      trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
                    ),
                  ),
                SizedBox(height: minDimension * 0.03),
                if (!isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isError ? Colors.red : Colors.grey).withOpacity(0.1),
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

  void _toggleSwitch(bool value) {
    if (widget.config.publishTopic == null) return;

    setState(() {
      _isLoading = true;
      _isOn = value;
    });

    final service = ref.read(mqttServiceProvider);
    final payload = value ? widget.config.onPayload! : widget.config.offPayload!;
    
    service.publish(
      widget.config.publishTopic!,
      payload,
      qos: widget.config.qos,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _showConnectionWarning(BuildContext context, String? lastError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lastError != null ? 'Tidak dapat publish: $lastError' : 'Koneksi MQTT belum tersambung'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}