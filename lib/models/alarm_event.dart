import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'alarm_event.g.dart';

@HiveType(typeId: 8)
enum AlarmSeverity {
  @HiveField(0) critical,
  @HiveField(1) major,
  @HiveField(2) minor,
}

@HiveType(typeId: 9)
enum AlarmStatus {
  @HiveField(0) active,       // Alarm is currently active
  @HiveField(1) acknowledged, // User acknowledged but still active
  @HiveField(2) cleared,      // Condition returned to normal
}

@HiveType(typeId: 10)
class AlarmEvent extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String ruleId;
  @HiveField(2) final String ruleName;
  @HiveField(3) final String sensorName;    // Widget/sensor name
  @HiveField(4) final AlarmSeverity severity;
  @HiveField(5) final DateTime startTime;
  @HiveField(6) DateTime? endTime;
  @HiveField(7) AlarmStatus status;
  @HiveField(8) final double triggerValue;
  @HiveField(9) final double thresholdValue;
  @HiveField(10) final String condition;     // e.g. "> 80"
  @HiveField(11) DateTime? acknowledgedTime;

  AlarmEvent({
    String? id,
    required this.ruleId,
    required this.ruleName,
    required this.sensorName,
    required this.severity,
    required this.startTime,
    this.endTime,
    this.status = AlarmStatus.active,
    required this.triggerValue,
    required this.thresholdValue,
    required this.condition,
    this.acknowledgedTime,
  }) : id = id ?? const Uuid().v4();

  // Calculate duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Format duration as string
  String get durationString {
    final d = duration;
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h';
    } else if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    } else {
      return '${d.inSeconds}s';
    }
  }

  bool get isActive => status == AlarmStatus.active || status == AlarmStatus.acknowledged;

  AlarmEvent copyWith({
    String? ruleName,
    String? sensorName,
    AlarmSeverity? severity,
    DateTime? startTime,
    DateTime? endTime,
    AlarmStatus? status,
    double? triggerValue,
    double? thresholdValue,
    String? condition,
    DateTime? acknowledgedTime,
  }) {
    return AlarmEvent(
      id: id,
      ruleId: ruleId,
      ruleName: ruleName ?? this.ruleName,
      sensorName: sensorName ?? this.sensorName,
      severity: severity ?? this.severity,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      triggerValue: triggerValue ?? this.triggerValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      condition: condition ?? this.condition,
      acknowledgedTime: acknowledgedTime ?? this.acknowledgedTime,
    );
  }
}
