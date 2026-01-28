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

  static const Map<String, List<IconData>> iconCategories = {
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

  // Cache for fast lookup
  static final Map<int, IconData> _iconLookup = {
    for (final icon in availableIcons) icon.codePoint: icon,
    for (final category in iconCategories.values)
      for (final icon in category) icon.codePoint: icon,
  };

  /// Gets an IconData from a codePoint.
  /// MaterialIcons use 'MaterialIcons' as fontFamily.
  static IconData? getIcon(int? codePoint) {
    if (codePoint == null) return null;
    return _iconLookup[codePoint] ?? Icons.help_outline;
  }
}
