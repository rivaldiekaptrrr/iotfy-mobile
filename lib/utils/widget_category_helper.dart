import '../models/panel_widget_config.dart';

enum WidgetCategory {
  charts,
  gauges,
  controls,
  maps,
  indicators,
  others,
}

class WidgetCategoryHelper {
  static WidgetCategory getCategory(WidgetType type) {
    switch (type) {
      // Charts
      case WidgetType.lineChart:
      case WidgetType.barChart:
      case WidgetType.kpiCard:
        return WidgetCategory.charts;

      // Gauges
      case WidgetType.gauge:
      case WidgetType.radialGauge:
      case WidgetType.linearGauge:
      case WidgetType.liquidTank:
      case WidgetType.battery:
        return WidgetCategory.gauges;

      // Controls
      case WidgetType.toggle:
      case WidgetType.button:
      case WidgetType.slider:
      case WidgetType.knob:
      case WidgetType.joystick:
      case WidgetType.keypad:
      case WidgetType.segmentedSwitch:
        return WidgetCategory.controls;
        
      // Maps & Location
      case WidgetType.map:
      case WidgetType.compass:
        return WidgetCategory.maps;

      // Indicators
      case WidgetType.statusIndicator:
      case WidgetType.iconMatrix:
        return WidgetCategory.indicators;

      // Others
      case WidgetType.text:
      case WidgetType.terminal:
      case WidgetType.alarm:
        return WidgetCategory.others;
    }
  }

  static String getCategoryLabel(WidgetCategory category) {
    switch (category) {
      case WidgetCategory.charts:
        return 'Charts';
      case WidgetCategory.gauges:
        return 'Gauges';
      case WidgetCategory.controls:
        return 'Controls';
      case WidgetCategory.maps:
        return 'Maps & Geo';
      case WidgetCategory.indicators:
        return 'Indicators';
      case WidgetCategory.others:
        return 'Others';
    }
  }
}
