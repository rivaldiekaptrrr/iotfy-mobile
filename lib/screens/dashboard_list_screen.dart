import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_config.dart';
import '../models/panel_widget_config.dart';
import '../providers/storage_providers.dart';
import '../providers/mqtt_providers.dart';
import '../utils/icon_helper.dart';
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
                      theme.colorScheme.primary.withValues(alpha: 0.05),
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
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dashboard_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Dashboard Templates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildTemplateTile(
                        context,
                        title: 'Environment Monitor',
                        subtitle: 'Temp, Humidity, Air Quality',
                        icon: Icons.thermostat_rounded,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          _createFromTemplate(
                            ref,
                            'Env Monitor',
                            Icons.thermostat_rounded.codePoint,
                            Colors.orange.toARGB32(),
                            [
                              // Row 1: Temp & Hum
                              PanelWidgetConfig(
                                title: 'Temperature',
                                type: WidgetType.gauge,
                                subscribeTopic: 'env/temp',
                                minValue: 0,
                                maxValue: 50,
                                unit: '°C',
                                colorValue: Colors.orange.toARGB32(),
                                x: 0,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              PanelWidgetConfig(
                                title: 'Humidity',
                                type: WidgetType.lineChart,
                                subscribeTopic: 'env/hum',
                                minValue: 0,
                                maxValue: 100,
                                unit: '%',
                                colorValue: Colors.blue.toARGB32(),
                                maxDataPoints: 50,
                                x: 4,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              // Row 2: Air Quality
                              PanelWidgetConfig(
                                title: 'Air Quality',
                                type: WidgetType.text,
                                subscribeTopic: 'env/iaq',
                                colorValue: Colors.green.toARGB32(),
                                x: 0,
                                y: 3,
                                width: 4,
                                height: 2,
                              ),
                            ],
                          );
                        },
                      ),
                      _buildTemplateTile(
                        context,
                        title: 'Smart Home Hub',
                        subtitle: 'Lights, Security, Sensors',
                        icon: Icons.home_rounded,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pop(context);
                          _createFromTemplate(
                            ref,
                            'Smart Home',
                            Icons.home_rounded.codePoint,
                            Colors.indigo.toARGB32(),
                            [
                              // Row 1: Light Switches
                              PanelWidgetConfig(
                                title: 'Living Room',
                                type: WidgetType.toggle,
                                subscribeTopic: 'home/living/light/state',
                                publishTopic: 'home/living/light/set',
                                onPayload: 'ON',
                                offPayload: 'OFF',
                                colorValue: Colors.amber.toARGB32(),
                                x: 0,
                                y: 0,
                                width: 4,
                                height: 2,
                              ),
                              PanelWidgetConfig(
                                title: 'Kitchen',
                                type: WidgetType.toggle,
                                subscribeTopic: 'home/kitchen/light/state',
                                publishTopic: 'home/kitchen/light/set',
                                onPayload: 'ON',
                                offPayload: 'OFF',
                                colorValue: Colors.amber.toARGB32(),
                                x: 4,
                                y: 0,
                                width: 4,
                                height: 2,
                              ),
                              // Row 2: Door & Temp
                              PanelWidgetConfig(
                                title: 'Front Door',
                                type: WidgetType.text,
                                subscribeTopic: 'home/door/front',
                                colorValue: Colors.red.toARGB32(),
                                x: 0,
                                y: 2,
                                width: 4,
                                height: 2,
                              ),
                              PanelWidgetConfig(
                                title: 'Temperature',
                                type: WidgetType.gauge,
                                subscribeTopic: 'home/temp',
                                minValue: 10,
                                maxValue: 40,
                                unit: '°C',
                                colorValue: Colors.orange.toARGB32(),
                                x: 4,
                                y: 2,
                                width: 4,
                                height: 3,
                              ),
                            ],
                          );
                        },
                      ),
                      _buildTemplateTile(
                        context,
                        title: 'Industrial Status',
                        subtitle: 'Machine State, RPM, Vibration',
                        icon: Icons.factory_rounded,
                        color: Colors.blueGrey,
                        onTap: () {
                          Navigator.pop(context);
                          _createFromTemplate(
                            ref,
                            'Factory Floor',
                            Icons.factory_rounded.codePoint,
                            Colors.blueGrey.toARGB32(),
                            [
                              // Row 1: Status & RPM
                              PanelWidgetConfig(
                                title: 'Machine Status',
                                type: WidgetType.text,
                                subscribeTopic: 'factory/machine/1/status',
                                colorValue: Colors.green.toARGB32(),
                                x: 0,
                                y: 0,
                                width: 4,
                                height: 2,
                              ),
                              PanelWidgetConfig(
                                title: 'Motor RPM',
                                type: WidgetType.gauge,
                                subscribeTopic: 'factory/motor/rpm',
                                minValue: 0,
                                maxValue: 3000,
                                unit: 'RPM',
                                colorValue: Colors.red.toARGB32(),
                                x: 4,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              // Row 2: Vibration Chart (Full Width)
                              PanelWidgetConfig(
                                title: 'Vibration',
                                type: WidgetType.lineChart,
                                subscribeTopic: 'factory/motor/vibration',
                                minValue: 0,
                                maxValue: 10,
                                unit: 'mm/s',
                                colorValue: Colors.orange.toARGB32(),
                                x: 0,
                                y: 3,
                                width: 8,
                                height: 4,
                              ),
                            ],
                          );
                        },
                      ),
                      _buildTemplateTile(
                        context,
                        title: 'Energy Monitor',
                        subtitle: 'Voltage, Current, Power Usage',
                        icon: Icons.bolt_rounded,
                        color: Colors.yellow.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          _createFromTemplate(
                            ref,
                            'Energy Meter',
                            Icons.bolt_rounded.codePoint,
                            Colors.yellow.shade800.toARGB32(),
                            [
                              // Row 1: Voltage & Current
                              PanelWidgetConfig(
                                title: 'Voltage',
                                type: WidgetType.gauge,
                                subscribeTopic: 'energy/voltage',
                                minValue: 200,
                                maxValue: 240,
                                unit: 'V',
                                colorValue: Colors.yellow.shade700.toARGB32(),
                                x: 0,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              PanelWidgetConfig(
                                title: 'Current',
                                type: WidgetType.gauge,
                                subscribeTopic: 'energy/current',
                                minValue: 0,
                                maxValue: 20,
                                unit: 'A',
                                colorValue: Colors.blue.toARGB32(),
                                x: 4,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              // Row 2: Power Chart
                              PanelWidgetConfig(
                                title: 'Power',
                                type: WidgetType.lineChart,
                                subscribeTopic: 'energy/power',
                                minValue: 0,
                                maxValue: 5000,
                                unit: 'W',
                                colorValue: Colors.red.toARGB32(),
                                x: 0,
                                y: 3,
                                width: 8,
                                height: 4,
                              ),
                            ],
                          );
                        },
                      ),
                      _buildTemplateTile(
                        context,
                        title: 'Server Room',
                        subtitle: 'UPS, Rack Temp, Load',
                        icon: Icons.dns_rounded,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          _createFromTemplate(
                            ref,
                            'Server Room',
                            Icons.dns_rounded.codePoint,
                            Colors.purple.toARGB32(),
                            [
                              // Row 1: Temp & UPS
                              PanelWidgetConfig(
                                title: 'Rack Temp',
                                type: WidgetType.gauge,
                                subscribeTopic: 'server/rack1/temp',
                                minValue: 15,
                                maxValue: 35,
                                unit: '°C',
                                colorValue: Colors.blue.toARGB32(),
                                x: 0,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              PanelWidgetConfig(
                                title: 'UPS Load',
                                type: WidgetType.lineChart,
                                subscribeTopic: 'server/ups/load',
                                minValue: 0,
                                maxValue: 100,
                                unit: '%',
                                colorValue: Colors.green.toARGB32(),
                                x: 4,
                                y: 0,
                                width: 4,
                                height: 3,
                              ),
                              // Row 2: Main Power
                              PanelWidgetConfig(
                                title: 'Main Power',
                                type: WidgetType.text,
                                subscribeTopic: 'server/power/source',
                                colorValue: Colors.amber.toARGB32(),
                                x: 0,
                                y: 3,
                                width: 4,
                                height: 2,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTemplateTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
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
    // Resolve Icon and Color
    final IconData icon =
        IconHelper.getIcon(dashboard.iconCodePoint) ?? Icons.dashboard_rounded;

    final Color color = dashboard.colorValue != null
        ? Color(dashboard.colorValue!)
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Subtle shadow
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
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
    _selectedColorValue = widget.initialColorValue ?? Colors.blue.toARGB32();
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
                children: IconHelper.iconCategories.entries.map((category) {
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
                                      ).withValues(alpha: 0.2)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: Color(_selectedColorValue),
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: theme.dividerColor.withValues(alpha: 
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
              final isSelected = color.toARGB32() == _selectedColorValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorValue = color.toARGB32()),
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
                        color: color.withValues(alpha: 0.4),
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
