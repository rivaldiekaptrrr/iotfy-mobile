import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
import '../widgets/panels/map_panel.dart';
import '../widgets/panels/slider_panel.dart';
import '../widgets/panels/alarm_panel.dart';
import '../widgets/panels/status_panel.dart';
import '../widgets/panels/kpi_panel.dart';
import '../widgets/panels/bar_chart_panel.dart';
import '../widgets/panels/liquid_tank_panel.dart';
import '../widgets/panels/radial_gauge_panel.dart';
import '../widgets/panels/knob_panel.dart';
import '../widgets/panels/battery_panel.dart';
import '../widgets/panels/terminal_panel.dart';
import '../widgets/panels/segmented_switch_panel.dart';
import '../widgets/panels/linear_gauge_panel.dart';
import '../widgets/panels/joystick_panel.dart';
import '../widgets/panels/compass_panel.dart';
import '../widgets/panels/keypad_panel.dart';
import '../widgets/panels/icon_matrix_panel.dart';
import 'widget_config_dialog.dart';
import 'broker_list_screen.dart';
import 'rule_manager_screen.dart';
import '../widgets/dashboard_grid_layout.dart';
import '../services/rule_evaluator_service.dart';
import '../widgets/pulsing_dot.dart';
import 'widget_catalog_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isEditMode = false;
  final double _gridSpacing = 16;
  final double _gridPadding = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App kembali dari background, check MQTT connection
      print('[LIFECYCLE] App resumed, checking MQTT connection...');
      _checkAndReconnectMqtt();
    } else if (state == AppLifecycleState.paused) {
      print('[LIFECYCLE] App paused (background)');
    }
  }

  void _checkAndReconnectMqtt() {
    final mqttService = ref.read(mqttServiceProvider);
    final connectionStatus = ref.read(connectionStatusProvider);

    // Jika status connected tapi mungkin stale, force reconnect
    if (connectionStatus.value == ConnectionStatus.connected) {
      // Ping test dengan subscribe ulang semua widget topics
      final dashboard = ref.read(currentDashboardProvider);
      if (dashboard != null) {
        print(
          '[LIFECYCLE] Resubscribing ${dashboard.widgets.length} widget topics...',
        );
        for (var widget in dashboard.widgets) {
          if (widget.subscribeTopic != null) {
            mqttService.subscribe(widget.subscribeTopic!, qos: widget.qos);
          }
        }
      }
    } else if (connectionStatus.value == ConnectionStatus.disconnected) {
      // Auto reconnect jika disconnected
      print('[LIFECYCLE] Connection lost, will auto-reconnect...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(currentDashboardProvider);
    final broker = dashboard != null
        ? ref
              .watch(brokerConfigsProvider.notifier)
              .getBroker(dashboard.brokerId)
        : null;
    final connectionStatus = ref.watch(connectionStatusProvider);
    final status = connectionStatus.value ?? ConnectionStatus.disconnected;
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;
    final isError = status == ConnectionStatus.error;
    final lastError = ref.watch(mqttServiceProvider).lastError;

    // Initialize rule evaluator service
    ref.watch(ruleEvaluatorProvider);

    if (dashboard == null) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboard.name),
        actions: [
          _buildConnectionStatus(
            isConnected,
            isConnecting,
            isError,
            lastError,
            status,
          ),
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
            tooltip: 'Rule Engine',
            icon: const Icon(Icons.rule),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RuleManagerScreen()),
            ),
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
                _buildHeader(
                  context,
                  dashboard,
                  broker,
                  isConnected,
                  isConnecting,
                  isError,
                  lastError,
                ),
                if (_isEditMode) _buildEditModeBanner(),
                Expanded(
                  child: DashboardGridLayout(
                    widgets: dashboard.widgets,
                    isEditMode: _isEditMode,
                    childBuilder: _buildWidget,
                    onWidgetUpdate: _updateWidgetConfig, // For drag/resize
                    onWidgetEdit: _editWidget,
                    onWidgetDelete: _deleteWidget,
                  ),
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

  Widget _buildConnectionStatus(
    bool isConnected,
    bool isConnecting,
    bool isError,
    String? lastError,
    ConnectionStatus status,
  ) {
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
                    PulsingDot(
                      color: isConnected
                          ? Colors.green
                          : isError
                          ? Colors.red
                          : Colors.grey,
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
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
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
          Icon(
            Icons.widgets_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Your dashboard is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).disabledColor,
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
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drag to move widgets. Drag corners to resize.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
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
        panel = Center(
          child: Text(
            config.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        );
        break;
      case WidgetType.map:
        panel = MapPanel(config: config);
        break;
      case WidgetType.slider:
        panel = SliderPanel(config: config);
        break;
      case WidgetType.alarm:
        panel = AlarmPanel(config: config);
        break;
      case WidgetType.statusIndicator:
        panel = StatusPanel(config: config);
        break;
      case WidgetType.kpiCard:
        panel = KPIPanel(config: config);
        break;
      case WidgetType.barChart:
        panel = BarChartPanel(config: config);
        break;
      case WidgetType.liquidTank:
        panel = LiquidTankPanel(config: config);
        break;
      case WidgetType.radialGauge:
        panel = RadialGaugePanel(config: config);
        break;
      case WidgetType.knob:
        panel = KnobPanel(config: config);
        break;
      case WidgetType.battery:
        panel = BatteryPanel(config: config);
        break;
      case WidgetType.terminal:
        panel = TerminalPanel(config: config);
        break;
      case WidgetType.segmentedSwitch:
        panel = SegmentedSwitchPanel(config: config);
        break;
      case WidgetType.linearGauge:
        panel = LinearGaugePanel(config: config);
        break;
      case WidgetType.joystick:
        panel = JoystickPanel(config: config);
        break;
      case WidgetType.compass:
        panel = CompassPanel(config: config);
        break;
      case WidgetType.keypad:
        panel = KeypadPanel(config: config);
        break;
      case WidgetType.iconMatrix:
        panel = IconMatrixPanel(config: config);
        break;
    }

    return PanelContainer(
      config: config,
      isEditMode: _isEditMode,
      onEdit: () => _editWidget(config),
      onDuplicate: () => _duplicateWidget(config),
      onDelete: () => _deleteWidget(config.id),
      child: panel,
    );
  }

  /* Widget Wraps Removed */

  Future<void> _addWidget() async {
    // 1. Open Catalog to select type
    final selectedType = await Navigator.push<WidgetType>(
      context,
      MaterialPageRoute(builder: (_) => const WidgetCatalogScreen()),
    );

    if (selectedType == null) return; // Cancelled

    // 2. Open Config Dialog with pre-selected type
    final config = await showDialog<PanelWidgetConfig>(
      context: context,
      builder: (_) => WidgetConfigDialog(preSelectedType: selectedType),
    );
    if (config != null) {
      final dashboard = ref.read(currentDashboardProvider);
      if (dashboard != null) {
        // Find a free spot (simple stack approach for now: put at bottom)
        double maxY = 0;
        for (var w in dashboard.widgets) {
          if ((w.y + w.height) > maxY) maxY = w.y + w.height;
        }

        final newConfig = config.copyWith(
          x: 0,
          y: maxY,
          width: switch (config.type) {
            WidgetType.toggle => 4,
            WidgetType.button => 4,
            WidgetType.text => 4,
            WidgetType.gauge => 6,
            WidgetType.lineChart => 8,
            WidgetType.map => 8,
            WidgetType.slider => 8,
            WidgetType.alarm => 12,
            WidgetType.statusIndicator => 4,
            WidgetType.kpiCard => 4,
            WidgetType.barChart => 8,
            WidgetType.liquidTank => 4,
            WidgetType.radialGauge => 5,
            WidgetType.knob => 4,
            WidgetType.battery => 4,
            WidgetType.terminal => 12,
            WidgetType.segmentedSwitch => 6,
            WidgetType.linearGauge => 8,
            WidgetType.joystick => 6,
            WidgetType.compass => 5,
            WidgetType.keypad => 6,
            WidgetType.iconMatrix => 6,
          },
          height: switch (config.type) {
            WidgetType.toggle => 4,
            WidgetType.button => 3,
            WidgetType.text => 3,
            WidgetType.gauge => 6,
            WidgetType.lineChart => 6,
            WidgetType.map => 8,
            WidgetType.slider => 3,
            WidgetType.alarm => 6,
            WidgetType.statusIndicator => 4,
            WidgetType.kpiCard => 4,
            WidgetType.barChart => 6,
            WidgetType.liquidTank => 7,
            WidgetType.radialGauge => 5,
            WidgetType.knob => 6,
            WidgetType.battery => 4,
            WidgetType.terminal => 8,
            WidgetType.segmentedSwitch => 3,
            WidgetType.linearGauge => 3,
            WidgetType.joystick => 6,
            WidgetType.compass => 5,
            WidgetType.keypad => 6,
            WidgetType.iconMatrix => 4,
          },
        );

        final updated = dashboard.copyWith(
          widgets: [...dashboard.widgets, newConfig],
        );
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
        final newWidgets = dashboard.widgets
            .map((w) => w.id == oldConfig.id ? editedConfig : w)
            .toList();
        final updated = dashboard.copyWith(widgets: newWidgets);
        ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
      }
    }
  }

  void _deleteWidget(String id) {
    // Changed signature to String for DashboardGridLayout compatibility if needed, but it was already String
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard != null) {
      final newWidgets = dashboard.widgets.where((w) => w.id != id).toList();
      final updated = dashboard.copyWith(widgets: newWidgets);
      ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
    }
  }

  void _duplicateWidget(PanelWidgetConfig config) {
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) return;

    // Find a free spot at the bottom
    double maxY = 0;
    for (var w in dashboard.widgets) {
      if ((w.y + w.height) > maxY) maxY = w.y + w.height;
    }

    final newConfig = config.copyWith(
      id: const Uuid().v4(),
      title: '${config.title} (Copy)',
      x: 0,
      y: maxY,
    );

    final updated = dashboard.copyWith(
      widgets: [...dashboard.widgets, newConfig],
    );
    ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated widget: ${newConfig.title}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _deleteWidget(newConfig.id),
          ),
        ),
      );
    }
  }

  // Called by DashboardGridLayout when x/y/w/h changes
  void _updateWidgetConfig(PanelWidgetConfig updatedConfig) {
    final dashboard = ref.read(currentDashboardProvider);
    if (dashboard == null) return;

    final newWidgets = dashboard.widgets
        .map((w) => w.id == updatedConfig.id ? updatedConfig : w)
        .toList();
    final updated = dashboard.copyWith(widgets: newWidgets);

    // We update the state immediately
    // Note: this triggers rebuilds on every drag frame if we are not careful.
    // DashboardGridLayout is throttled or local state based?
    // It calls this onPanUpdate. That might be heavy.
    // Ideally we optimize, but for now let's see.
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
                    const Text(
                      'System Logs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    // Direct access to log buffer - instant, no stream waiting!
                    final mqttService = ref.watch(mqttServiceProvider);
                    final entries = mqttService.logBuffer;

                    // Listen to stream for rebuild trigger only
                    ref.listen(mqttLogsProvider, (_, __) {});

                    return entries.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs recorded',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
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
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            entry.level.name.toUpperCase(),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          entry.time
                                              .toLocal()
                                              .toIso8601String()
                                              .substring(11, 19),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(
                                              context,
                                            ).disabledColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.message,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
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
              child: Icon(
                Icons.hub_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broker != null ? broker.name : 'Unknown Broker',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    broker != null
                        ? '${broker.host}:${broker.port}'
                        : 'No broker config',
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
  final VoidCallback onDuplicate;

  const PanelContainer({
    super.key,
    required this.config,
    required this.child,
    required this.isEditMode,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
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
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _buildEditAction(
                    icon: Icons.close_rounded,
                    color: Colors.white,
                    bg: Colors.red,
                    onTap: onDelete,
                  ),
                  const SizedBox(width: 4),
                  _buildEditAction(
                    icon: Icons.copy_rounded,
                    color: Colors.white,
                    bg: Colors.orange,
                    onTap: onDuplicate,
                  ),
                ],
              ),
            ),
          ),

        if (isEditMode) /* Resize handle is now outside PanelContainer in DashboardGridLayout */
          Container(),
      ],
    );
  }

  Widget _buildEditAction({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
