import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/broker_config.dart';
import '../models/dashboard_config.dart';
import '../models/panel_widget_config.dart';

// Broker Configs Provider
class BrokerConfigsNotifier extends StateNotifier<List<BrokerConfig>> {
  BrokerConfigsNotifier() : super([]) {
    _loadBrokers();
  }

  Box<BrokerConfig>? _box;

  Future<void> _loadBrokers() async {
    _box = await Hive.openBox<BrokerConfig>('brokers');
    state = _box!.values.toList();
  }

  Future<void> addBroker(BrokerConfig broker) async {
    await _box?.put(broker.id, broker);
    state = [...state, broker];
  }

  Future<void> updateBroker(BrokerConfig broker) async {
    await _box?.put(broker.id, broker);
    state = [
      for (final b in state)
        if (b.id == broker.id) broker else b,
    ];
  }

  Future<void> deleteBroker(String id) async {
    await _box?.delete(id);
    state = state.where((b) => b.id != id).toList();
  }

  BrokerConfig? getBroker(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }
}

final brokerConfigsProvider = StateNotifierProvider<BrokerConfigsNotifier, List<BrokerConfig>>((ref) {
  return BrokerConfigsNotifier();
});

// Dashboard Configs Provider
class DashboardConfigsNotifier extends StateNotifier<List<DashboardConfig>> {
  DashboardConfigsNotifier() : super([]) {
    _loadDashboards();
  }

  Box<DashboardConfig>? _box;

  Future<void> _loadDashboards() async {
    _box = await Hive.openBox<DashboardConfig>('dashboards');
    state = _box!.values.toList();
  }

  Future<void> addDashboard(DashboardConfig dashboard) async {
    await _box?.put(dashboard.id, dashboard);
    state = [...state, dashboard];
  }

  Future<void> updateDashboard(DashboardConfig dashboard) async {
    await _box?.put(dashboard.id, dashboard);
    state = [
      for (final d in state)
        if (d.id == dashboard.id) dashboard else d,
    ];
  }

  Future<void> deleteDashboard(String id) async {
    await _box?.delete(id);
    state = state.where((d) => d.id != id).toList();
  }

  DashboardConfig? getDashboard(String id) {
    try {
      return state.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
}

final dashboardConfigsProvider = StateNotifierProvider<DashboardConfigsNotifier, List<DashboardConfig>>((ref) {
  return DashboardConfigsNotifier();
});

// Current Dashboard Provider
final currentDashboardIdProvider = StateProvider<String?>((ref) => null);

final currentDashboardProvider = Provider<DashboardConfig?>((ref) {
  final dashboardId = ref.watch(currentDashboardIdProvider);
  if (dashboardId == null) return null;
  
  final notifier = ref.watch(dashboardConfigsProvider.notifier);
  return notifier.getDashboard(dashboardId);
});