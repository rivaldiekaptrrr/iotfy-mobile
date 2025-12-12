import 'package:flutter/material.dart';

class IconHelper {
  // Predefined icons that users can choose from in the widget config dialog
  static const List<IconData> availableIcons = [
    Icons.lightbulb,
    Icons.power_settings_new,
    Icons.toggle_on,
    Icons.outlet,
    Icons.thermostat,
    Icons.water_drop,
    Icons.air,
    Icons.sensors,
    Icons.flash_on,
    Icons.ac_unit,
    Icons.security,
    Icons.lock,
    Icons.door_front_door,
    Icons.garage,
    Icons.window,
    Icons.speaker,
    Icons.tv,
    Icons.router,
    Icons.developer_board,
    Icons.memory,
  ];

  /// Gets an IconData from a codePoint.
  /// MaterialIcons use 'MaterialIcons' as fontFamily.
  static IconData? getIcon(int? codePoint) {
    if (codePoint == null) return null;
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }
}