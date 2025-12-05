import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'broker_config.g.dart';

@HiveType(typeId: 0)
class BrokerConfig extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String host;

  @HiveField(3)
  int port;

  @HiveField(4)
  String? username;

  @HiveField(5)
  String? password;

  @HiveField(6)
  bool useSsl;

  @HiveField(7)
  String? clientId;

  @HiveField(8)
  int keepAlivePeriod;

  @HiveField(9)
  bool cleanSession;

  BrokerConfig({
    String? id,
    required this.name,
    required this.host,
    this.port = 1883,
    this.username,
    this.password,
    this.useSsl = false,
    this.clientId,
    this.keepAlivePeriod = 60,
    this.cleanSession = true,
  }) : id = id ?? const Uuid().v4();

  BrokerConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? useSsl,
    String? clientId,
    int? keepAlivePeriod,
    bool? cleanSession,
  }) {
    return BrokerConfig(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
      clientId: clientId ?? this.clientId,
      keepAlivePeriod: keepAlivePeriod ?? this.keepAlivePeriod,
      cleanSession: cleanSession ?? this.cleanSession,
    );
  }
}