import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/broker_config.dart';
import '../models/dashboard_config.dart';
import '../services/secure_credential_storage.dart';

// Broker Configs
class BrokerConfigsNotifier extends StateNotifier<List<BrokerConfig>> {
  BrokerConfigsNotifier() : super([]) { _loadBrokers(); }

  Box<BrokerConfig>? _box;
  final SecureCredentialStorage _secureStorage = SecureCredentialStorage();

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
    state = state.map((b) => b.id == broker.id ? broker : b).toList();
  }

  Future<void> deleteBroker(String id) async {
    // Hapus credentials dari secure storage juga
    await _secureStorage.deleteBrokerCredentials(id);
    await _box?.delete(id);
    state = state.where((b) => b.id != id).toList();
  }

  BrokerConfig? getBroker(String id) => state.cast<BrokerConfig?>().firstWhere((b) => b!.id == id, orElse: () => null);
}

final brokerConfigsProvider = StateNotifierProvider<BrokerConfigsNotifier, List<BrokerConfig>>((ref) => BrokerConfigsNotifier());

// Dashboard Configs
class DashboardConfigsNotifier extends StateNotifier<List<DashboardConfig>> {
  DashboardConfigsNotifier() : super([]) { _loadDashboards(); }

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
    state = state.map((d) => d.id == dashboard.id ? dashboard : d).toList();
  }

  Future<void> deleteDashboard(String id) async {
    await _box?.delete(id);
    state = state.where((d) => d.id != id).toList();
  }

  DashboardConfig? getDashboard(String id) =>
      state.cast<DashboardConfig?>().firstWhere((d) => d!.id == id, orElse: () => null);
}

final dashboardConfigsProvider = StateNotifierProvider<DashboardConfigsNotifier, List<DashboardConfig>>((ref) => DashboardConfigsNotifier());

final currentDashboardIdProvider = StateProvider<String?>((ref) => null);

final currentDashboardProvider = Provider<DashboardConfig?>((ref) {
  final id = ref.watch(currentDashboardIdProvider);
  final dashboards = ref.watch(dashboardConfigsProvider);
  if (id == null) return null;
  final found = dashboards.where((d) => d.id == id);
  return found.isNotEmpty ? found.first : null;
});

// Secure Credential Storage Provider
final secureCredentialStorageProvider = Provider<SecureCredentialStorage>((ref) {
  return SecureCredentialStorage();
});
