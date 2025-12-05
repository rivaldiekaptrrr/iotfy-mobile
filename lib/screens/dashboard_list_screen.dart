import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_config.dart';
import '../providers/storage_providers.dart';
import '../providers/mqtt_providers.dart';
import 'dashboard_screen.dart';

class DashboardListScreen extends ConsumerWidget {
  final String brokerId;

  const DashboardListScreen({super.key, required this.brokerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDashboards = ref.watch(dashboardConfigsProvider);
    final dashboards = allDashboards.where((d) => d.brokerId == brokerId).toList();
    final broker = ref.watch(brokerConfigsProvider.notifier).getBroker(brokerId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${broker?.name ?? "Broker"} Dashboards'),
      ),
      body: dashboards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No dashboards yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _createDashboard(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Dashboard'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: dashboards.length,
              itemBuilder: (context, index) {
                final dashboard = dashboards[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.dashboard),
                    ),
                    title: Text(dashboard.name),
                    subtitle: Text(
                      '${dashboard.widgets.length} widgets • Updated ${DateFormat.yMd().add_jm().format(dashboard.updatedAt)}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            Future.delayed(Duration.zero, () => _editDashboard(context, ref, dashboard));
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Duplicate'),
                          onTap: () {
                            final copy = DashboardConfig(
                              name: '${dashboard.name} (Copy)',
                              brokerId: dashboard.brokerId,
                              widgets: dashboard.widgets,
                            );
                            ref.read(dashboardConfigsProvider.notifier).addDashboard(copy);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () {
                            ref.read(dashboardConfigsProvider.notifier).deleteDashboard(dashboard.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _openDashboard(context, ref, dashboard),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDashboard(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createDashboard(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _DashboardNameDialog(
        onSave: (name) {
          final dashboard = DashboardConfig(
            name: name,
            brokerId: brokerId,
          );
          ref.read(dashboardConfigsProvider.notifier).addDashboard(dashboard);
        },
      ),
    );
  }

  void _editDashboard(BuildContext context, WidgetRef ref, DashboardConfig dashboard) {
    showDialog(
      context: context,
      builder: (context) => _DashboardNameDialog(
        initialName: dashboard.name,
        onSave: (name) {
          final updated = dashboard.copyWith(name: name);
          ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
        },
      ),
    );
  }

  void _openDashboard(BuildContext context, WidgetRef ref, DashboardConfig dashboard) async {
    ref.read(currentDashboardIdProvider.notifier).state = dashboard.id;
    
    // Connect to broker
    final broker = ref.read(brokerConfigsProvider.notifier).getBroker(brokerId);
    if (broker != null) {
      final service = ref.read(mqttServiceProvider);
      await service.connect(broker);
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }
}

class _DashboardNameDialog extends StatefulWidget {
  final String? initialName;
  final Function(String) onSave;

  const _DashboardNameDialog({this.initialName, required this.onSave});

  @override
  State<_DashboardNameDialog> createState() => _DashboardNameDialogState();
}

class _DashboardNameDialogState extends State<_DashboardNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Create Dashboard' : 'Edit Dashboard'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Dashboard Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}