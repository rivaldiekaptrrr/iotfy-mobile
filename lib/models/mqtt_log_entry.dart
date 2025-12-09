enum MqttLogLevel { info, warn, error }

class MqttLogEntry {
  final DateTime time;
  final MqttLogLevel level;
  final String message;

  MqttLogEntry({
    required this.time,
    required this.level,
    required this.message,
  });
}



