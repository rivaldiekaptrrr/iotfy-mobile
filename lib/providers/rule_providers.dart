import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/rule_config.dart';

class RuleConfigsNotifier extends StateNotifier<List<RuleConfig>> {
  final Box<RuleConfig> _box;

  RuleConfigsNotifier(this._box) : super(_box.values.toList()) {
    _box.watch().listen((_) {
      state = _box.values.toList();
    });
  }

  void addRule(RuleConfig rule) {
    _box.put(rule.id, rule);
    state = [...state, rule];
  }

  void updateRule(RuleConfig rule) {
    _box.put(rule.id, rule);
    state = state.map((r) => r.id == rule.id ? rule : r).toList();
  }

  void deleteRule(String id) {
    _box.delete(id);
    state = state.where((r) => r.id != id).toList();
  }

  void toggleRuleActive(String id) {
    final rule = state.firstWhere((r) => r.id == id);
    final updated = rule.copyWith(isActive: !rule.isActive);
    updateRule(updated);
  }

  List<RuleConfig> getRulesForDashboard(String dashboardId) {
    return state.where((r) => r.dashboardId == dashboardId).toList();
  }

  List<RuleConfig> getActiveRulesForDashboard(String dashboardId) {
    return state
        .where((r) => r.dashboardId == dashboardId && r.isActive)
        .toList();
  }

  void recordTrigger(String ruleId) {
    final rule = state.firstWhere((r) => r.id == ruleId);
    final updated = rule.copyWith(
      lastTriggeredAt: DateTime.now(),
      triggerCount: rule.triggerCount + 1,
    );
    updateRule(updated);
  }

  RuleConfig? getRule(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}

final ruleConfigsProvider =
    StateNotifierProvider<RuleConfigsNotifier, List<RuleConfig>>((ref) {
      final box = Hive.box<RuleConfig>('rule_configs');
      return RuleConfigsNotifier(box);
    });
