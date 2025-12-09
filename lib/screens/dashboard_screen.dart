import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderables/reorderables.dart';
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
  final double _gridSpacing = 16;
  final double _gridPadding = 16;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(currentDashboardProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.value == ConnectionStatus.connected;
    final isConnecting = connectionStatus.value == ConnectionStatus.connecting;
    final isError = connectionStatus.value == ConnectionStatus.error;
    final lastError = ref.watch(mqttServiceProvider).lastError;

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
                  Tooltip(
                    message: isConnected
                        ? 'Connected'
                        : isConnecting
                            ? 'Connecting...'
                            : isError
                                ? 'Error: ${lastError ?? "Unknown"}'
                                : 'Disconnected',
                    child: Row(
                      children: [
                        if (isConnecting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? Colors.green
                                  : isError
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected
                              ? 'Connected'
                              : isConnecting
                                  ? 'Connecting...'
                                  : isError
                                      ? 'Error'
                                      : 'Disconnected',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
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
          : _isEditMode
              ? Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.drag_indicator),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Edit mode: drag to reorder. Use width buttons to set 1x1 or 2x1.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildEditableWrap(context, dashboard.widgets),
                    ),
                  ],
                )
              : _buildReadonlyWrap(context, dashboard.widgets),
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
                    child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 4),
                // Resize width
                GestureDetector(
                  onTap: () => _updateWidgetSpan(config, 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ]),
                    child: const Icon(Icons.stop, size: 18, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _updateWidgetSpan(config, 2),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ]),
                    child: const Icon(Icons.view_week, size: 18, color: Colors.black87),
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
                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReadonlyWrap(BuildContext context, List<PanelWidgetConfig> widgets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (_gridPadding * 2);
        final columnWidth = (availableWidth - _gridSpacing) / 2;

        return SingleChildScrollView(
          padding: EdgeInsets.all(_gridPadding),
          child: Wrap(
            spacing: _gridSpacing,
            runSpacing: _gridSpacing,
            children: widgets.map((config) {
              final span = config.width.clamp(1, 2).toInt();
              final width = span == 2 ? availableWidth : columnWidth;
              return SizedBox(
                key: ValueKey(config.id),
                width: width,
                child: _buildWidget(config),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEditableWrap(BuildContext context, List<PanelWidgetConfig> widgets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (_gridPadding * 2);
        final columnWidth = (availableWidth - _gridSpacing) / 2;

        return SingleChildScrollView(
          padding: EdgeInsets.all(_gridPadding),
          child: ReorderableWrap(
            spacing: _gridSpacing,
            runSpacing: _gridSpacing,
            needsLongPressDraggable: true,
            children: widgets.map((config) {
              final span = config.width.clamp(1, 2).toInt();
              final width = span == 2 ? availableWidth : columnWidth;
              return SizedBox(
                key: ValueKey(config.id),
                width: width,
                child: Stack(
                  children: [
                    _buildWidget(config),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator, size: 16),
                          const SizedBox(width: 6),
                          Text('Span ${span}x1', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onReorder: (oldIndex, newIndex) => _reorderWidget(oldIndex, newIndex),
          ),
        );
      },
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

  void _updateWidgetSpan(PanelWidgetConfig config, int span) {
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) return;
    final clampedSpan = span.clamp(1, 2).toDouble();
    final newWidgets = dashboard.widgets
        .map((w) => w.id == config.id ? w.copyWith(width: clampedSpan) : w)
        .toList();
    final updated = dashboard.copyWith(widgets: newWidgets);
    ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
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