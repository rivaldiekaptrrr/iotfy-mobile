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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrokerListScreen()),
              ),
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrokerListScreen()),
                ),
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
          // Connection status
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
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrokerListScreen()),
            ),
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
                  const Text('No widgets yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first widget', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
          : ReorderableGridView(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: dashboard.widgets.map((config) => _buildWidget(config)).toList(),
              onReorder: (oldIndex, newIndex) => _reorderWidget(oldIndex, newIndex),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWidget,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWidget(PanelWidgetConfig config) {
    Widget panel;
    switch (config.type) {
      case WidgetType.toggle:
        panel = TogglePanel(config: config);
        break;
      case WidgetType.button:
        panel = ButtonPanel(config: config);
        break;
      case WidgetType.gauge:
        panel = GaugePanel(config: config);
        break;
      case WidgetType.lineChart:
        panel = LineChartPanel(config: config);
        break;
      case WidgetType.text:
        panel = Card(child: Center(child: Text(config.title)));
        break;
    }

    // Wrap dengan Stack agar bisa menampilkan tombol edit/delete saat edit mode
    return Stack(
      key: ValueKey(config.id),
      children: [
        panel,
        if (_isEditMode)
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Edit
                GestureDetector(
                  onTap: () => _editWidget(config),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ]),
                    child: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 4),
                // Tombol Delete
                GestureDetector(
                  onTap: () => _deleteWidget(config.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ]),
                    child: const Icon(Icons.close, size: 20, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _addWidget() async {
    final config = await showDialog<PanelWidgetConfig>(
      context: context,
      builder: (_) => const WidgetConfigDialog(),
    );
    if (config != null) {
      final dashboard = ref.read(currentDashboardProvider);
      if (dashboard != null) {
        final updated = dashboard.copyWith(widgets: [...dashboard.widgets, config]);
        ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
      }
    }
  }

  void _editWidget(PanelWidgetConfig oldConfig) async {
    final editedConfig = await showDialog<PanelWidgetConfig>(
      context: context,
      builder: (_) => WidgetConfigDialog(initialConfig: oldConfig),
    );
    if (editedConfig != null) {
      final dashboard = ref.read(currentDashboardProvider);
      if (dashboard != null) {
        final newWidgets = dashboard.widgets.map((w) => w.id == oldConfig.id ? editedConfig : w).toList();
        final updated = dashboard.copyWith(widgets: newWidgets);
        ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
      }
    }
  }

  void _deleteWidget(String id) {
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard != null) {
      final newWidgets = dashboard.widgets.where((w) => w.id != id).toList();
      final updated = dashboard.copyWith(widgets: newWidgets);
      ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
    }
  }

  void _reorderWidget(int oldIndex, int newIndex) {
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) return;

    final List<PanelWidgetConfig> widgets = List.from(dashboard.widgets);
    final moved = widgets.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    widgets.insert(newIndex, moved);

    final updated = dashboard.copyWith(widgets: widgets);
    ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
  }
}

// Helper widget untuk GridView yang bisa drag & drop
class ReorderableGridView extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;
  final Function(int, int) onReorder;

  const ReorderableGridView({
    super.key,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.padding,
    required this.children,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}