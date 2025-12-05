import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/panel_widget_config.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../services/mqtt_service.dart';
import '../widgets/panels/toggle_panel.dart';
import '../widgets/panels/button_panel.dart';
import '../widgets/panels/gauge_panel.dart';
import '../widgets/panels/line_chart_panel.dart';
import 'widget_config_dialog.dart';
import 'broker_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(currentDashboardProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;

    if (dashboard == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('IoT MQTT Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrokerListScreen()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No dashboard selected',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BrokerListScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboard.name),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrokerListScreen()),
              );
            },
          ),
        ],
      ),
      body: dashboard.widgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.widgets_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No widgets yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first widget',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: dashboard.widgets.length,
              itemBuilder: (context, index) {
                final widget = dashboard.widgets[index];
                return _buildWidget(widget);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWidget,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWidget(PanelWidgetConfig config) {
    switch (config.type) {
      case WidgetType.toggle:
        return TogglePanel(config: config);
      case WidgetType.button:
        return ButtonPanel(config: config);
      case WidgetType.gauge:
        return GaugePanel(config: config);
      case WidgetType.lineChart:
        return LineChartPanel(config: config);
      case WidgetType.text:
        return Card(
          child: Center(
            child: Text(config.title),
          ),
        );
    }
  }

  Future<void> _addWidget() async {
    final config = await showDialog<PanelWidgetConfig>(
      context: context,
      builder: (context) => const WidgetConfigDialog(),
    );

    if (config != null) {
      final dashboard = ref.read(currentDashboardProvider);
      if (dashboard != null) {
        final updatedDashboard = dashboard.copyWith(
          widgets: [...dashboard.widgets, config],
        );
        ref.read(dashboardConfigsProvider.notifier).updateDashboard(updatedDashboard);
      }
    }
  }
}