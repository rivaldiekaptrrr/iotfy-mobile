import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderables/reorderables.dart';
import '../models/panel_widget_config.dart';
import '../models/dashboard_config.dart';
import '../models/broker_config.dart';
import '../models/mqtt_log_entry.dart';
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
  final double _gridPadding = 20;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(currentDashboardProvider);
    final broker = dashboard != null
        ? ref.watch(brokerConfigsProvider.notifier).getBroker(dashboard.brokerId)
        : null;
    final connectionStatus = ref.watch(connectionStatusProvider);
    final status = connectionStatus.value ?? ConnectionStatus.disconnected;
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;
    final isError = status == ConnectionStatus.error;
    final lastError = ref.watch(mqttServiceProvider).lastError;

    if (dashboard == null) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboard.name),
        actions: [
          _buildConnectionStatus(isConnected, isConnecting, isError, lastError, status),
          IconButton(
            tooltip: 'Logs',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => _openLogSheet(context),
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit_outlined),
            color: _isEditMode ? Theme.of(context).colorScheme.primary : null,
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrokerListScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboard.widgets.isEmpty
          ? _buildEmptyDashboardState()
          : Column(
              children: [
                _buildHeader(context, dashboard, broker, isConnected, isConnecting, isError, lastError),
                if (_isEditMode) _buildEditModeBanner(),
                Expanded(
                  child: _isEditMode
                      ? _buildEditableWrap(context, dashboard.widgets)
                      : _buildReadonlyWrap(context, dashboard.widgets),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWidget,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Widget'),
      ),
    );
  }

  Widget _buildConnectionStatus(bool isConnected, bool isConnecting, bool isError, String? lastError, ConnectionStatus status) {
     return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Tooltip(
                message: isConnected
                    ? 'Connected'
                    : isConnecting
                        ? 'Connecting...'
                        : isError
                            ? 'Error: ${lastError ?? "Unknown"}'
                            : 'Disconnected',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(status),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.withOpacity(0.1)
                          : isError
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                         color: isConnected
                          ? Colors.green.withOpacity(0.5)
                          : isError
                              ? Colors.red.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                         width: 1,     
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnecting)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? Colors.green
                                  : isError
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected
                              ? 'Online'
                              : isConnecting
                                  ? '...'
                                  : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isConnected
                                ? Colors.green
                                : isError
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

   Widget _buildEmptyState(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('IoT MQTT Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.dashboard_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Dashboard Selected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
               const SizedBox(height: 8),
              const Text(
                'Create a new dashboard or select an existing one.',
                 style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
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

   Widget _buildEmptyDashboardState() {
     return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_outlined, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'Your dashboard is empty',
               style: Theme.of(context).textTheme.titleLarge?.copyWith(
                 color: Theme.of(context).disabledColor
               ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add widgets to visualize your data',
               style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          ],
        ),
      );
   }

  Widget _buildEditModeBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _gridPadding, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
           Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drag to reorder widgets. Use actions on widgets to resize or delete.',
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onTertiaryContainer
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidget(PanelWidgetConfig config) {
    Widget panel;
    // Remove Card Check - widgets handled internally now
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
        panel = Center(
          child: Text(
            config.title, 
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          )
        );
        break;
    }

    return PanelContainer(
      key: ValueKey(config.id),
      config: config,
      isEditMode: _isEditMode,
      onEdit: () => _editWidget(config),
      onDelete: () => _deleteWidget(config.id),
      onResize: (span) => _updateWidgetSpan(config, span),
      child: panel,
    );
  }

  Widget _buildReadonlyWrap(BuildContext context, List<PanelWidgetConfig> widgets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (_gridPadding * 2);
        final columnWidth = (availableWidth - _gridSpacing) / 2;

        return SingleChildScrollView(
          padding: EdgeInsets.all(_gridPadding),
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: _gridSpacing,
            runSpacing: _gridSpacing,
            children: widgets.map((config) {
              final span = config.width.clamp(1, 2).toInt();
              final width = span == 2 ? availableWidth : columnWidth;
              return SizedBox(
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
          physics: const BouncingScrollPhysics(),
          child: ReorderableWrap(
            spacing: _gridSpacing,
            runSpacing: _gridSpacing,
            needsLongPressDraggable: false, // Easier drag
            children: widgets.map((config) {
              final span = config.width.clamp(1, 2).toInt();
              final width = span == 2 ? availableWidth : columnWidth;
              return SizedBox(
                key: ValueKey(config.id),
                width: width,
                child: _buildWidget(config),
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

  void _openLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
               Padding(
                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('System Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                     TextButton(
                       onPressed: () => Navigator.pop(context), 
                       child: const Text('Close')
                     ),
                   ],
                 ),
               ),
               const Divider(height: 1),
               Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final logs = ref.watch(mqttLogsProvider);
                    return logs.when(
                      data: (entries) => entries.isEmpty
                          ? const Center(child: Text('No logs recorded', style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final entry = entries[entries.length - 1 - index];
                                final color = switch (entry.level) {
                                  MqttLogLevel.info => Colors.blue,
                                  MqttLogLevel.warn => Colors.orange,
                                  MqttLogLevel.error => Colors.red,
                                };
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              entry.level.name.toUpperCase(),
                                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            entry.time.toLocal().toIso8601String().substring(11, 19),
                                            style: TextStyle(fontSize: 10, color: Theme.of(context).disabledColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(entry.message, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                );
                              },
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Failed to load logs')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DashboardConfig dashboard,
    BrokerConfig? broker,
    bool isConnected,
    bool isConnecting,
    bool isError,
    String? lastError,
  ) {
    // Header information wrapped in a cleaner card
    return Padding(
      padding: EdgeInsets.fromLTRB(_gridPadding, 12, _gridPadding, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 10,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.hub_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broker != null ? broker.name : 'Unknown Broker',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    broker != null ? '${broker.host}:${broker.port}' : 'No broker config',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
             if (broker != null)
              IconButton.outlined(
                tooltip: 'Reconnect',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () async {
                  await ref.read(mqttServiceProvider).connect(broker);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class PanelContainer extends StatelessWidget {
  final PanelWidgetConfig config;
  final Widget child;
  final bool isEditMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int) onResize;

  const PanelContainer({
    super.key,
    required this.config,
    required this.child,
    required this.isEditMode,
    required this.onEdit,
    required this.onDelete,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? Colors.white;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 blurRadius: 10,
                 offset: const Offset(0, 4),
               ),
            ],
            border: Border.all(
              color: isEditMode 
                  ? theme.colorScheme.primary.withOpacity(0.5) 
                  : theme.dividerColor.withOpacity(0.1),
              width: isEditMode ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
        
        // Edit Overlays
        if (isEditMode)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  _buildEditAction(
                    icon: Icons.edit_rounded, 
                    color: Colors.white, 
                    bg: Colors.blue, 
                    onTap: onEdit
                  ),
                  const SizedBox(width: 4),
                  _buildEditAction(
                    icon: Icons.close_rounded, 
                    color: Colors.white, 
                    bg: Colors.red, 
                    onTap: onDelete
                  ),
                ],
              ),
            )
          ),

        if (isEditMode)
           Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                 color: Colors.black87,
                 borderRadius: BorderRadius.circular(12),
              ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   GestureDetector(
                     onTap: () => onResize(1),
                     child: Icon(Icons.crop_portrait_sharp, size: 16, color: config.width < 1.5 ? Colors.blueAccent : Colors.white),
                   ),
                   const SizedBox(width: 8),
                   GestureDetector(
                     onTap: () => onResize(2),
                     child: Icon(Icons.crop_landscape_sharp, size: 16, color: config.width >= 1.5 ? Colors.blueAccent : Colors.white),
                   ),
                 ],
               ),
            ),
           ),
      ],
    );
  }

  Widget _buildEditAction({required IconData icon, required Color color, required Color bg, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
             BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}