import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'panel_widget_config.dart';

part 'dashboard_config.g.dart';

@HiveType(typeId: 1)
class DashboardConfig extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String brokerId;

  @HiveField(3)
  List<PanelWidgetConfig> widgets;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  int? iconCodePoint;

  @HiveField(7)
  int? colorValue;

  DashboardConfig({
    String? id,
    required this.name,
    required this.brokerId,
    List<PanelWidgetConfig>? widgets,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.iconCodePoint,
    this.colorValue,
  }) : id = id ?? const Uuid().v4(),
       widgets = widgets ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  DashboardConfig copyWith({
    String? name,
    String? brokerId,
    List<PanelWidgetConfig>? widgets,
    DateTime? updatedAt,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return DashboardConfig(
      id: id,
      name: name ?? this.name,
      brokerId: brokerId ?? this.brokerId,
      widgets: widgets ?? this.widgets,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
