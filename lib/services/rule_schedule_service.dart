import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../providers/rule_providers.dart';
import 'rule_evaluator_service.dart';

class RuleScheduleService {
  final Ref ref;
  Timer? _timer;

  RuleScheduleService(this.ref) {
    debugPrint('[SCHEDULE] Service starting...');
    _startTimer();
  }

  void _startTimer() {
    // Check every 30 seconds to be safe on minute transitions
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkSchedules(),
    );
  }

  void _checkSchedules() {
    final rules = ref.read(ruleConfigsProvider);
    final now = DateTime.now();

    for (final rule in rules) {
      if (!rule.isActive ||
          rule.triggerType != RuleTriggerType.schedule ||
          rule.scheduleConfig == null) {
        continue;
      }

      if (_shouldTrigger(rule, now)) {
        debugPrint('[SCHEDULE] Triggering rule: ${rule.name}');
        ref.read(ruleEvaluatorProvider).triggerRuleManually(rule.id);
      }
    }
  }

  bool _shouldTrigger(RuleConfig rule, DateTime now) {
    final config = rule.scheduleConfig!;
    final lastTriggered = rule.lastTriggeredAt;

    switch (config.type) {
      case ScheduleType.once:
        if (config.executeAt == null) return false;
        // Trigger if now is after execution time AND it hasn't been triggered yet
        return lastTriggered == null && now.isAfter(config.executeAt!);

      case ScheduleType.daily:
        if (config.dailyTimeMinutes == null) return false;
        // Check if current time matches scheduled minutes
        final nowTotalMinutes = now.hour * 60 + now.minute;
        if (nowTotalMinutes != config.dailyTimeMinutes) return false;

        // Prevent multiple triggers in the same minute
        if (lastTriggered != null &&
            lastTriggered.year == now.year &&
            lastTriggered.month == now.month &&
            lastTriggered.day == now.day &&
            lastTriggered.hour == now.hour &&
            lastTriggered.minute == now.minute) {
          return false;
        }
        return true;

      case ScheduleType.weekly:
        if (config.weeklyTimeMinutes == null || config.weekdays == null) {
          return false;
        }
        if (!config.weekdays!.contains(now.weekday)) return false;

        final nowTotalMinutes = now.hour * 60 + now.minute;
        if (nowTotalMinutes != config.weeklyTimeMinutes) return false;

        // Prevent multiple triggers in the same minute
        if (lastTriggered != null &&
            lastTriggered.year == now.year &&
            lastTriggered.month == now.month &&
            lastTriggered.day == now.day &&
            lastTriggered.hour == now.hour &&
            lastTriggered.minute == now.minute) {
          return false;
        }
        return true;

      case ScheduleType.interval:
        if (config.intervalMinutes == null) return false;
        if (lastTriggered == null) {
          // If never triggered, we can trigger now or wait for first interval.
          // Triggering now is usually what users expect when they create an interval rule.
          return true;
        }
        return now.difference(lastTriggered).inMinutes >=
            config.intervalMinutes!;
    }
  }

  void dispose() {
    debugPrint('[SCHEDULE] Service stopping...');
    _timer?.cancel();
  }
}

final ruleScheduleProvider = Provider<RuleScheduleService>((ref) {
  final service = RuleScheduleService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
