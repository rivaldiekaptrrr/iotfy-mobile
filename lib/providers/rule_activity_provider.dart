import 'package:flutter_riverpod/flutter_riverpod.dart';

class RuleActivityLog {
  final String id;
  final String ruleName;
  final String actionDescription;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;

  RuleActivityLog({
    required this.id,
    required this.ruleName,
    required this.actionDescription,
    required this.timestamp,
    this.isSuccess = true,
    this.errorMessage,
  });
}

class RuleActivityNotifier extends StateNotifier<List<RuleActivityLog>> {
  RuleActivityNotifier() : super([]);

  void addLog({
    required String ruleName,
    required String actionDescription,
    bool isSuccess = true,
    String? errorMessage,
  }) {
    final log = RuleActivityLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ruleName: ruleName,
      actionDescription: actionDescription,
      timestamp: DateTime.now(),
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );

    // Keep only last 50 logs
    state = [log, ...state].take(50).toList();
  }

  void clearLogs() {
    state = [];
  }
}

final ruleActivityProvider =
    StateNotifierProvider<RuleActivityNotifier, List<RuleActivityLog>>((ref) {
      return RuleActivityNotifier();
    });
