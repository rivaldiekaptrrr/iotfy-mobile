import 'package:flutter/material.dart';
import '../models/panel_widget_config.dart';
import '../utils/widget_category_helper.dart';
import '../utils/icon_helper.dart';

class WidgetCatalogScreen extends StatelessWidget {
  const WidgetCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Widget'),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildCategoryCard(context, WidgetCategory.charts, [
            Icons.show_chart,
            Icons.bar_chart,
            Icons.analytics,
          ]),
          _buildCategoryCard(context, WidgetCategory.gauges, [
            Icons.speed,
            Icons.timelapse,
            Icons.water,
            Icons.battery_full,
          ]),
          _buildCategoryCard(context, WidgetCategory.controls, [
            Icons.toggle_on,
            Icons.tune,
            Icons.radio_button_checked,
            Icons.gamepad,
          ]),
          _buildCategoryCard(context, WidgetCategory.maps, [
            Icons.map,
            Icons.explore,
            Icons.place,
          ]),
          _buildCategoryCard(context, WidgetCategory.indicators, [
            Icons.circle,
            Icons.grid_view,
            Icons.traffic,
          ]),
          _buildCategoryCard(context, WidgetCategory.others, [
            Icons.text_fields,
            Icons.terminal,
            Icons.notifications_active,
          ]),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetCategory category,
    List<IconData> previewIcons,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showWidgetSelection(context, category),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Title
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      WidgetCategoryHelper.getCategoryLabel(category),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            // Preview Area (Visual Representation)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: previewIcons.map((icon) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      size: 20,
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWidgetSelection(BuildContext context, WidgetCategory category) {
    // Get all widgets for this category
    final widgets = WidgetType.values.where((type) => WidgetCategoryHelper.getCategory(type) == category).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select ${WidgetCategoryHelper.getCategoryLabel(category)} Widget',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widgets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final type = widgets[index];
                  return _buildWidgetListItem(context, type);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetListItem(BuildContext context, WidgetType type) {
    // Helper to get friendly name and icon
    String name = type.name.toUpperCase();
    IconData icon = Icons.widgets;
    String description = 'Widget';

    switch (type) {
      // Monitoring
      case WidgetType.gauge:
        name = 'Gauge';
        icon = Icons.speed;
        description = 'Analog gauge for sensor values';
        break;
      case WidgetType.lineChart:
        name = 'Line Chart';
        icon = Icons.show_chart;
        description = 'Real-time historical data graph';
        break;
      case WidgetType.map:
        name = 'Map';
        icon = Icons.map;
        description = 'GPS tracking and location';
        break;
      case WidgetType.text:
        name = 'Text / Value';
        icon = Icons.text_fields;
        description = 'Simple text or value display';
        break;
      case WidgetType.alarm:
        name = 'Alarm List';
        icon = Icons.notifications_active;
        description = 'List of triggered alarms';
        break;
      case WidgetType.statusIndicator:
        name = 'Status Indicator';
        icon = Icons.circle;
        description = 'LED-like status light';
        break;
      case WidgetType.kpiCard:
        name = 'KPI Card';
        icon = Icons.analytics;
        description = 'Key Performance Indicator with trend';
        break;
      case WidgetType.barChart:
        name = 'Bar Chart';
        icon = Icons.bar_chart;
        description = 'Categorical data comparison';
        break;
      case WidgetType.liquidTank:
        name = 'Liquid Tank';
        icon = Icons.water;
        description = 'Tank level visualization';
        break;
      case WidgetType.radialGauge:
        name = 'Radial Gauge';
        icon = Icons.timelapse; // Close enough
        description = 'Circular progress gauge';
        break;
      case WidgetType.battery:
        name = 'Battery';
        icon = Icons.battery_full;
        description = 'Battery level indicator';
        break;
      case WidgetType.linearGauge:
        name = 'Linear Gauge';
        icon = Icons.linear_scale;
        description = 'Linear progress bar';
        break;
      case WidgetType.compass:
        name = 'Compass';
        icon = Icons.explore;
        description = 'Direction indicator';
        break;
        
      // Controlling
      case WidgetType.toggle:
        name = 'Toggle Switch';
        icon = Icons.toggle_on;
        description = 'On/Off switch control';
        break;
      case WidgetType.button:
        name = 'Push Button';
        icon = Icons.radio_button_checked; // Push button look
        description = 'Momentary or toggle button';
        break;
      case WidgetType.slider:
        name = 'Slider';
        icon = Icons.tune;
        description = 'Adjustable value slider';
        break;
      case WidgetType.knob:
        name = 'Knob';
        icon = Icons.radio_button_unchecked; // Knob look
        description = 'Rotary control knob';
        break;
      case WidgetType.terminal:
        name = 'Terminal';
        icon = Icons.terminal;
        description = 'Command line interface';
        break;
      case WidgetType.segmentedSwitch:
        name = 'Segmented Switch';
        icon = Icons.view_column;
        description = 'Multi-state switch';
        break;
      case WidgetType.joystick:
        name = 'Joystick';
        icon = Icons.gamepad;
        description = '2-axis control';
        break;
      case WidgetType.keypad:
        name = 'Keypad';
        icon = Icons.dialpad;
        description = 'Numeric keypad input';
        break;
        
      // Others
      case WidgetType.iconMatrix:
        name = 'Icon Matrix';
        icon = Icons.grid_view;
        description = 'Grid of status icons';
        break;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        onTap: () {
          // Close sheet and return widget type to the Catalog Screen,
          // which will then pop to Dashboard with the type.
          Navigator.pop(context); // Pop sheet
          Navigator.pop(context, type); // Pop catalog
        },
      ),
    );
  }
}
