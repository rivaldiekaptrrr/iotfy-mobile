import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_event.dart';

class AlarmEventsNotifier extends StateNotifier<List<AlarmEvent>> {
  final Box<AlarmEvent> _box;

  AlarmEventsNotifier(this._box) : super(_box.values.toList()) {
    _box.watch().listen((_) {
      state = _box.values.toList();
    });
  }

  void addAlarm(AlarmEvent alarm) {
    _box.put(alarm.id, alarm);
    state = [...state, alarm];
  }

  void updateAlarm(AlarmEvent alarm) {
    _box.put(alarm.id, alarm);
    state = state.map((a) => a.id == alarm.id ? alarm : a).toList();
  }

  void acknowledgeAlarm(String alarmId) {
    final alarm = state.firstWhere((a) => a.id == alarmId);
    final updated = alarm.copyWith(
      status: AlarmStatus.acknowledged,
      acknowledgedTime: DateTime.now(),
    );
    updateAlarm(updated);
  }

  void clearAlarm(String alarmId) {
    final alarm = state.firstWhere((a) => a.id == alarmId);
    final updated = alarm.copyWith(
      status: AlarmStatus.cleared,
      endTime: DateTime.now(),
    );
    updateAlarm(updated);
  }

  List<AlarmEvent> getActiveAlarms({int? limit}) {
    final active = state.where((a) => a.isActive).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Latest first
    
    if (limit != null && active.length > limit) {
      return active.sublist(0, limit);
    }
    return active;
  }

  List<AlarmEvent> getAllAlarms({int? limit}) {
    final all = state.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Latest first
    
    if (limit != null && all.length > limit) {
      return all.sublist(0, limit);
    }
    return all;
  }

  List<AlarmEvent> getAlarmsBySeverity(AlarmSeverity severity, {int? limit}) {
    final filtered = state.where((a) => a.severity == severity && a.isActive).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    if (limit != null && filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  // Find active alarm for a specific rule
  AlarmEvent? getActiveAlarmForRule(String ruleId) {
    try {
      return state.firstWhere(
        (a) => a.ruleId == ruleId && a.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  // Clear all alarms from storage
  void clearAllAlarms() {
    _box.clear();
    state = [];
  }
}

final alarmEventsProvider = StateNotifierProvider<AlarmEventsNotifier, List<AlarmEvent>>((ref) {
  final box = Hive.box<AlarmEvent>('alarm_events');
  return AlarmEventsNotifier(box);
});
