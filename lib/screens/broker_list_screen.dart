import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/broker_config.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../services/mqtt_service.dart';
import 'broker_form_screen.dart';
import 'dashboard_list_screen.dart';

class BrokerListScreen extends ConsumerWidget {
  const BrokerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brokers = ref.watch(brokerConfigsProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Brokers'),
      ),
      body: brokers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No brokers configured',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addBroker(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Broker'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: brokers.length,
              itemBuilder: (context, index) {
                final broker = brokers[index];
                final isConnected = connectionStatus.value == ConnectionStatus.connected;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isConnected ? Colors.green : Colors.grey,
                      child: Icon(
                        isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(broker.name),
                    subtitle: Text('${broker.host}:${broker.port}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            Future.delayed(Duration.zero, () => _editBroker(context, broker));
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () {
                            ref.read(brokerConfigsProvider.notifier).deleteBroker(broker.id);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Dashboards'),
                          onTap: () {
                            Future.delayed(
                              Duration.zero,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DashboardListScreen(brokerId: broker.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () => _connectToBroker(ref, broker),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBroker(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addBroker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BrokerFormScreen()),
    );
  }

  void _editBroker(BuildContext context, BrokerConfig broker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BrokerFormScreen(broker: broker)),
    );
  }

  Future<void> _connectToBroker(WidgetRef ref, BrokerConfig broker) async {
    final service = ref.read(mqttServiceProvider);
    final success = await service.connect(broker);

    if (!success) {
      // Show error
    }
  }
}