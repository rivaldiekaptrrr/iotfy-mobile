import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mqtt_service.dart';
import '../models/mqtt_message.dart' as app_mqtt;

final mqttServiceProvider = Provider<MqttService>((ref) {
  return MqttService();
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.connectionStatus;
});

final mqttMessagesProvider = StreamProvider<app_mqtt.MqttMessageData>((ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.messages;
});