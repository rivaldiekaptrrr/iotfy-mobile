import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/broker_config.dart';
import '../models/mqtt_message.dart' as app_mqtt;

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  BrokerConfig? _currentConfig;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final Duration _baseReconnectDelay = const Duration(seconds: 2);
  final Duration _maxReconnectDelay = const Duration(seconds: 30);

  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _messageController = StreamController<app_mqtt.MqttMessageData>.broadcast();

  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<app_mqtt.MqttMessageData> get messages => _messageController.stream;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  bool _autoReconnect = true;
  String? _lastError;
  String? get lastError => _lastError;

  void _updateStatus(ConnectionStatus status, [String? error]) {
    _status = status;
    _lastError = error;
    _connectionStatusController.add(status);
  }

  Future<bool> connect(BrokerConfig config, {bool autoReconnect = true}) async {
    try {
      _autoReconnect = autoReconnect;
      _currentConfig = config;
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connecting);

      await disconnect();

      final clientId = config.clientId ?? 'flutter_mqtt_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(config.host, clientId, config.port);

      // Configure client settings
      _client!.logging(on: false);
      _client!.keepAlivePeriod = config.keepAlivePeriod;
      _client!.connectTimeoutPeriod = 10000; // 10 seconds timeout
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.autoReconnect = false;
      _client!.secure = config.useSsl;
      _client!.setProtocolV311(); // Use MQTT 3.1.1 protocol

      if (config.useSsl) {
        _client!.securityContext = SecurityContext.defaultContext;
        _client!.onBadCertificate = (dynamic certificate) => true; // Accept self-signed certificates
      }

      // Create connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean() // Clean session
          .withWillQos(MqttQos.atMostOnce)
          .keepAliveFor(config.keepAlivePeriod);

      if (config.username != null && config.username!.isNotEmpty) {
        connMessage.authenticateAs(config.username!, config.password ?? '');
      }

      _client!.connectionMessage = connMessage;

      // Try to connect
      try {
        await _client!.connect();
      } on Exception catch (e) {
        _client!.disconnect();
        final errorMsg = 'Connection failed: ${e.toString()}';
        _updateStatus(ConnectionStatus.error, errorMsg);
        if (_autoReconnect) {
          _scheduleReconnect();
        }
        return false;
      }

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _updateStatus(ConnectionStatus.connected);
        _reconnectAttempts = 0;
        _setupMessageListener();
        return true;
      } else {
        final errorMsg = 'Connection failed: ${_client!.connectionStatus!.returnCode}';
        _updateStatus(ConnectionStatus.error, errorMsg);
        if (_autoReconnect) {
          _scheduleReconnect();
        }
        return false;
      }
    } catch (e) {
      final errorMsg = 'Connection error: $e';
      _updateStatus(ConnectionStatus.error, errorMsg);
      if (_autoReconnect) {
        _scheduleReconnect();
      }
      return false;
    }
  }

  void _setupMessageListener() {
    _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final recMess = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        _messageController.add(app_mqtt.MqttMessageData(
          topic: message.topic,
          payload: payload,
        ));
      }
    });
  }

  void _onConnected() {
    _updateStatus(ConnectionStatus.connected);
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
  }

  void _onDisconnected() {
    _updateStatus(ConnectionStatus.disconnected);
    if (_autoReconnect && _currentConfig != null) {
      _scheduleReconnect();
    }
  }

  void _onSubscribed(String topic) {
    // Topic subscribed successfully
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delaySeconds = min(
      _maxReconnectDelay.inSeconds,
      _baseReconnectDelay.inSeconds * pow(2, _reconnectAttempts).toInt(),
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_currentConfig != null && _autoReconnect) {
        connect(_currentConfig!);
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    if (_client != null) {
      _updateStatus(ConnectionStatus.disconnecting);
      _client!.disconnect();
      _client = null;
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  void subscribe(String topic, {int qos = 0}) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.values[qos]);
    }
  }

  void unsubscribe(String topic) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.unsubscribe(topic);
    }
  }

  void publish(String topic, String payload, {int qos = 0, bool retain = false}) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      _client!.publishMessage(topic, MqttQos.values[qos], builder.payload!, retain: retain);
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _connectionStatusController.close();
    _messageController.close();
  }
}