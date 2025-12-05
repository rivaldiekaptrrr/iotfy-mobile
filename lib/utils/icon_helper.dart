import 'package:flutter/material.dart';

class IconHelper {
  static const Map<int, IconData> iconMap = {
    0xe0f4: Icons.lightbulb,
    0xe8ac: Icons.power_settings_new,
    0xe9f6: Icons.toggle_on,
    0xe3b5: Icons.outlet,
    0xe1ff: Icons.thermostat,
    0xefbe: Icons.water_drop,
    0xe146: Icons.air,
    0xe51e: Icons.sensors,
  };

  static IconData? getIcon(int? codePoint) {
    if (codePoint == null) return null;
    return iconMap[codePoint];
  }
}