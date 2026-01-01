import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class StatusPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const StatusPanel({super.key, required this.config});

  @override
  ConsumerState<StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends ConsumerState<StatusPanel> {
  String? _lastPayload;
  DateTime? _lastUpdated;
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
              _lastPayload = message.payload;
              _lastUpdated = DateTime.now();
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
    
    // Determine status
    bool isActive = false;
    bool isOff = false;
    
    if (_lastPayload != null) {
      if (_lastPayload == widget.config.onPayload) {
        isActive = true;
      } else if (_lastPayload == widget.config.offPayload) {
        isOff = true;
      }
    }

    final activeColor = widget.config.color; // User selected color for "Active"
    final inactiveColor = Colors.grey; 
    final warningColor = Colors.orange;

    Color stateColor;
    String stateText;
    IconData stateIcon;

    if (!isConnected) {
      stateColor = Colors.grey.withOpacity(0.5);
      stateText = 'Offline';
      stateIcon = Icons.wifi_off;
    } else if (_lastPayload == null) {
      stateColor = Colors.grey.withOpacity(0.3);
      stateText = 'Waiting...';
      stateIcon = Icons.hourglass_empty;
    } else if (isActive) {
      stateColor = activeColor;
      stateText = _lastPayload!;
      stateIcon = Icons.check_circle;
    } else if (isOff) {
      stateColor = inactiveColor; // Maybe allow configuring "Off" color? Default to grey/red interaction?
      // Let's make "Off" explicitly Red if the user chose Green for Active, or just Grey? 
      // Usually Status Indicator: Green=OK, Red=Stop.
      // But user configures ONE color. 
      // Let's assume Off is always Grey/Red-dish? Or let's just use Grey for off.
      stateColor = Colors.grey;
      stateText = _lastPayload!;
      stateIcon = Icons.power_settings_new;
    } else {
      stateColor = warningColor;
      stateText = _lastPayload!;
      stateIcon = Icons.warning_amber_rounded;
    }

    // Override icon if user selected one
    if (widget.config.icon != null) {
      stateIcon = widget.config.icon!;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stateColor.withOpacity(0.2),
              border: Border.all(
                color: stateColor,
                width: 4,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: stateColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Icon(
              stateIcon,
              size: 40,
              color: stateColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stateText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: stateColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (_lastUpdated != null)
             Text(
              'Updated: ${_lastUpdated!.toLocal().toString().split('.')[0].split(' ')[1]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
