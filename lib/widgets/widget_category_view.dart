import 'package:flutter/material.dart';
import '../models/panel_widget_config.dart';
import '../utils/widget_category_helper.dart';

class WidgetCategoryView extends StatelessWidget {
  final List<PanelWidgetConfig> widgets;
  final WidgetCategory category;
  final Widget Function(PanelWidgetConfig) childBuilder;

  const WidgetCategoryView({
    super.key,
    required this.widgets,
    required this.category,
    required this.childBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Filter widgets by category
    final categoryWidgets = widgets
        .where((w) => WidgetCategoryHelper.getCategory(w.type) == category)
        .toList();

    if (categoryWidgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 64,
              color: Theme.of(context).disabledColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${WidgetCategoryHelper.getCategoryLabel(category)} widgets yet',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive Grid Calculation
          // Base column width
          const double minCardWidth = 160; 
          
          final int crossAxisCount = (constraints.maxWidth / minCardWidth).floor().clamp(2, 6);
          final double cardWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: categoryWidgets.map((config) {
              // Calculate widget size based on its configuration relative to our grid
              // For visualization in category view, we try to respect their aspect ratio but normalize size
              // or just give them standard sizes.
              // Let's use a standard size logic but respecting 'w' and 'h' multipliers slightly?
              // Or simpler: Standard size cards for the list view.
              
              // Let's try to infer a good size.
              // Standard unit = cardWidth
              double w = config.width.clamp(1.0, crossAxisCount.toDouble());
              double h = config.height.clamp(1.0, 4.0);
              
              // We'll enforce a max width for this view to keep it neat
              if (w > crossAxisCount) w = crossAxisCount.toDouble();

              return SizedBox(
                 width: (w * cardWidth) + ((w - 1) * 16),
                 height: (h * cardWidth) + ((h - 1) * 16), // Square basics
                 child: childBuilder(config),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(WidgetCategory category) {
    switch (category) {
      case WidgetCategory.charts:
        return Icons.bar_chart;
      case WidgetCategory.gauges:
        return Icons.speed;
      case WidgetCategory.controls:
        return Icons.touch_app;
      case WidgetCategory.maps:
        return Icons.map;
      case WidgetCategory.indicators:
        return Icons.lightbulb_outline;
      case WidgetCategory.others:
        return Icons.grid_view;
    }
  }
}
