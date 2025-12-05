class MqttMessageData {
  final String topic;
  final String payload;
  final DateTime timestamp;

  MqttMessageData({
    required this.topic,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}