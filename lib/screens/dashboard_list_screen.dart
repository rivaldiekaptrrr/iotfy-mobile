import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_config.dart';
import '../models/panel_widget_config.dart';
import '../providers/storage_providers.dart';
import '../providers/mqtt_providers.dart';
import 'dashboard_screen.dart';

class DashboardListScreen extends ConsumerWidget {
  final String brokerId;

  const DashboardListScreen({super.key, required this.brokerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allDashboards = ref.watch(dashboardConfigsProvider);
    final dashboards = allDashboards
        .where((d) => d.brokerId == brokerId)
        .toList();
    final broker = ref
        .watch(brokerConfigsProvider.notifier)
        .getBroker(brokerId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            expandedHeight: 160,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 48,
                bottom: 20,
                right: 24,
              ),
              title: Text(
                broker?.name ?? 'Dashboards',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontSize: 24,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.05),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton.filledTonal(
                onPressed: () => _openTemplates(context, ref),
                icon: const Icon(Icons.auto_awesome_outlined),
                tooltip: 'Templates',
              ),
              const SizedBox(width: 16),
            ],
          ),

          if (dashboards.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, ref),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final dashboard = dashboards[index];
                  return _DashboardPremiumCard(
                    dashboard: dashboard,
                    onTap: () => _openDashboard(context, ref, dashboard),
                    onEdit: () => _editDashboard(context, ref, dashboard),
                    onDuplicate: () {
                      final copy = DashboardConfig(
                        name: '${dashboard.name} (Copy)',
                        brokerId: dashboard.brokerId,
                        widgets: dashboard.widgets,
                        iconCodePoint: dashboard.iconCodePoint,
                        colorValue: dashboard.colorValue,
                      );
                      ref
                          .read(dashboardConfigsProvider.notifier)
                          .addDashboard(copy);
                    },
                    onDelete: () => ref
                        .read(dashboardConfigsProvider.notifier)
                        .deleteDashboard(dashboard.id),
                  );
                }, childCount: dashboards.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDashboard(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Dashboard'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dashboard_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No Dashboards Found',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a new dashboard to visualize your data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => _createDashboard(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create New'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _openTemplates(context, ref),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Use Template'),
            ),
          ],
        ),
      ],
    );
  }

  void _createDashboard(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _DashboardFormDialog(
        onSave: (name, iconCode, colorVal) {
          final dashboard = DashboardConfig(
            name: name,
            brokerId: brokerId,
            iconCodePoint: iconCode,
            colorValue: colorVal,
          );
          ref.read(dashboardConfigsProvider.notifier).addDashboard(dashboard);
        },
      ),
    );
  }

  void _editDashboard(
    BuildContext context,
    WidgetRef ref,
    DashboardConfig dashboard,
  ) {
    showDialog(
      context: context,
      builder: (context) => _DashboardFormDialog(
        initialName: dashboard.name,
        initialIconCode: dashboard.iconCodePoint,
        initialColorValue: dashboard.colorValue,
        onSave: (name, iconCode, colorVal) {
          final updated = dashboard.copyWith(
            name: name,
            iconCodePoint: iconCode,
            colorValue: colorVal,
            updatedAt: DateTime.now(), // Force update timestamp
          );
          ref.read(dashboardConfigsProvider.notifier).updateDashboard(updated);
        },
      ),
    );
  }

  void _openTemplates(BuildContext context, WidgetRef ref) {
    // Template logic mostly same, just add icons
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Text(
                    'Quick Start Templates',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.thermostat, color: Colors.orange),
                  ),
                  title: const Text('Environment Monitor'),
                  subtitle: const Text(
                    'Gauge + Line chart for temperature & humidity',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _createFromTemplate(
                      ref,
                      'Env Monitor',
                      Icons.thermostat.codePoint,
                      Colors.orange.value,
                      [
                        // ... widgets ...
                        PanelWidgetConfig(
                          title: 'Temperature',
                          type: WidgetType.gauge,
                          subscribeTopic: 'env/temp',
                          minValue: 0,
                          maxValue: 50,
                          colorValue: Colors.orange.value,
                          x: 0,
                          y: 0,
                          width: 6,
                          height: 6,
                        ),
                        PanelWidgetConfig(
                          title: 'Humidity',
                          type: WidgetType.lineChart,
                          subscribeTopic: 'env/hum',
                          minValue: 0,
                          maxValue: 100,
                          colorValue: Colors.blue.value,
                          x: 6,
                          y: 0,
                          width: 6,
                          height: 6,
                        ),
                      ],
                    );
                  },
                ),
                // Add more templates as needed
              ],
            ),
          ),
        );
      },
    );
  }

  void _createFromTemplate(
    WidgetRef ref,
    String name,
    int iconCode,
    int colorVal,
    List<PanelWidgetConfig> widgets,
  ) {
    final dash = DashboardConfig(
      name: name,
      brokerId: brokerId,
      widgets: widgets,
      iconCodePoint: iconCode,
      colorValue: colorVal,
    );
    ref.read(dashboardConfigsProvider.notifier).addDashboard(dash);
  }

  void _openDashboard(
    BuildContext context,
    WidgetRef ref,
    DashboardConfig dashboard,
  ) async {
    ref.read(currentDashboardIdProvider.notifier).state = dashboard.id;
    final mqttService = ref.read(mqttServiceProvider);
    final currentConfig = mqttService.currentConfig;
    if (currentConfig?.id != brokerId) {
      final broker = ref
          .read(brokerConfigsProvider.notifier)
          .getBroker(brokerId);
      if (broker != null) {
        await mqttService.connect(broker);
      }
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}

class _DashboardPremiumCard extends StatelessWidget {
  final DashboardConfig dashboard;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _DashboardPremiumCard({
    required this.dashboard,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Resolve Icon and Color
    final IconData icon = dashboard.iconCodePoint != null
        ? IconData(dashboard.iconCodePoint!, fontFamily: 'MaterialIcons')
        : Icons.dashboard_rounded;

    final Color color = dashboard.colorValue != null
        ? Color(dashboard.colorValue!)
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Subtle shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Customized Logo Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    dashboard.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: -0.2, // Tighter premium feel
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Actions: Details & Menu
                // Detail Info Button
                IconButton(
                  onPressed: () {
                    // Show details dialog or bottom sheet
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(dashboard.name),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Widgets: ${dashboard.widgets.length}'),
                            const SizedBox(height: 8),
                            Text(
                              'Created: ${DateFormat.yMMMd().format(dashboard.createdAt)}',
                            ),
                            Text(
                              'Last Updated: ${DateFormat.yMMMd().add_Hm().format(dashboard.updatedAt)}',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.outline,
                    size: 22,
                  ),
                  tooltip: 'Details',
                ),

                // Menu
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 12),
                          Text('Edit Config'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDuplicate,
                      child: const Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 12),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardFormDialog extends StatefulWidget {
  final String? initialName;
  final int? initialIconCode;
  final int? initialColorValue;
  final Function(String name, int iconCode, int colorVal) onSave;

  const _DashboardFormDialog({
    this.initialName,
    this.initialIconCode,
    this.initialColorValue,
    required this.onSave,
  });

  @override
  State<_DashboardFormDialog> createState() => _DashboardFormDialogState();
}

class _DashboardFormDialogState extends State<_DashboardFormDialog> {
  late TextEditingController _nameController;
  late int _selectedIconCode;
  late int _selectedColorValue;

  final Map<String, List<IconData>> _iconCategories = {
    'General': [
      Icons.dashboard_rounded,
      Icons.analytics_rounded,
      Icons.show_chart_rounded,
    ],
    'Smart Home': [
      Icons.home_rounded,
      Icons.cottage_rounded,
      Icons.apartment_rounded,
      Icons.lightbulb_rounded,
      Icons.thermostat_rounded,
      Icons.door_front_door_rounded,
      Icons.security_rounded,
      Icons.videocam_rounded,
      Icons.sensor_door_rounded,
      Icons.meeting_room_rounded,
      Icons.kitchen_rounded,
      Icons.living_rounded,
    ],
    'Smart Farm': [
      Icons.agriculture_rounded,
      Icons.grass_rounded,
      Icons.eco_rounded,
      Icons.local_florist_rounded,
      Icons.forest_rounded,
      Icons.park_rounded,
      Icons.yard_rounded,
      Icons.spa_rounded,
      Icons.nature_rounded,
    ],
    'Industry': [
      Icons.factory_rounded,
      Icons.precision_manufacturing_rounded,
      Icons.construction_rounded,
      Icons.handyman_rounded,
      Icons.engineering_rounded,
      Icons.science_rounded,
      Icons.biotech_rounded,
    ],
    'Energy': [
      Icons.bolt_rounded,
      Icons.electric_bolt_rounded,
      Icons.power_rounded,
      Icons.battery_charging_full_rounded,
      Icons.solar_power_rounded,
      Icons.wb_sunny_rounded,
      Icons.gas_meter_rounded,
      Icons.oil_barrel_rounded,
    ],
    'Water & Environment': [
      Icons.water_drop_rounded,
      Icons.water_rounded,
      Icons.waves_rounded,
      Icons.cloud_rounded,
      Icons.air_rounded,
      Icons.thunderstorm_rounded,
      Icons.umbrella_rounded,
    ],
    'Sensors & Monitoring': [
      Icons.sensors_rounded,
      Icons.speed_rounded,
      Icons.radar_rounded,
      Icons.settings_input_component_rounded,
      Icons.router_rounded,
      Icons.hub_rounded,
      Icons.device_hub_rounded,
    ],
    'Transportation': [
      Icons.local_shipping_rounded,
      Icons.directions_car_rounded,
      Icons.two_wheeler_rounded,
      Icons.traffic_rounded,
      Icons.garage_rounded,
    ],
    'Retail': [
      Icons.store_rounded,
      Icons.storefront_rounded,
      Icons.shopping_cart_rounded,
      Icons.restaurant_rounded,
      Icons.local_cafe_rounded,
      Icons.bakery_dining_rounded,
    ],
    'Healthcare': [
      Icons.medical_services_rounded,
      Icons.health_and_safety_rounded,
      Icons.vaccines_rounded,
      Icons.local_hospital_rounded,
    ],
    'Others': [
      Icons.pets_rounded,
      Icons.warehouse_rounded,
      Icons.inventory_rounded,
      Icons.qr_code_scanner_rounded,
      Icons.vpn_lock_rounded,
    ],
  };

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIconCode =
        widget.initialIconCode ?? Icons.dashboard_rounded.codePoint;
    _selectedColorValue = widget.initialColorValue ?? Colors.blue.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'New Dashboard' : 'Edit Dashboard',
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Dashboard Name',
              hintText: 'e.g. Living Room',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Icon Picker
          Text('Select Icon', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _iconCategories.entries.map((category) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Text(
                          category.key,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Icons Wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: category.value.map((icon) {
                          final isSelected =
                              icon.codePoint == _selectedIconCode;
                          return InkWell(
                            onTap: () => setState(
                              () => _selectedIconCode = icon.codePoint,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(
                                        _selectedColorValue,
                                      ).withOpacity(0.2)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: Color(_selectedColorValue),
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: theme.dividerColor.withOpacity(
                                          0.3,
                                        ),
                                      ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? Color(_selectedColorValue)
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Color Picker
          Text('Select Color', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableColors.map((color) {
              final isSelected = color.value == _selectedColorValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorValue = color.value),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onSave(
                _nameController.text.trim(),
                _selectedIconCode,
                _selectedColorValue,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
