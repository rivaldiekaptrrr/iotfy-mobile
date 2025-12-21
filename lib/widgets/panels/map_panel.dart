import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/panel_widget_config.dart';
import '../../models/mqtt_message.dart' as app_mqtt;
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class MapPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const MapPanel({super.key, required this.config});

  @override
  ConsumerState<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends ConsumerState<MapPanel> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(-6.2088, 106.8456); // Default: Jakarta
  bool _hasReceivedData = false;
  final List<LatLng> _path = [];
  ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>>? _messageSub;
  bool _isFirstUpdate = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    _messageSub = ref.listenManual<AsyncValue<app_mqtt.MqttMessageData>>(
      mqttMessagesProvider,
      (_, next) {
        next.whenData((message) {
          if (message.topic == widget.config.subscribeTopic) {
            _handleMessage(message.payload);
          }
        });
      },
    );
  }

  void _subscribeToTopic() {
    if (widget.config.subscribeTopic != null) {
      final service = ref.read(mqttServiceProvider);
      service.subscribe(widget.config.subscribeTopic!, qos: widget.config.qos);
    }
  }

  @override
  void didUpdateWidget(MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.subscribeTopic != oldWidget.config.subscribeTopic) {
      _subscribeToTopic();
    }
    if (widget.config.isMovingMode != oldWidget.config.isMovingMode) {
      // Clear path when switching to static mode
      if (!widget.config.isMovingMode) {
        _path.clear();
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _messageSub?.close();
    _mapController.dispose();
    super.dispose();
  }

  void _handleMessage(String payload) {
    if (!mounted) return;
    
    try {
      final data = json.decode(payload);
      if (data is Map<String, dynamic> &&
          data.containsKey('lat') &&
          data.containsKey('lng')) {
        final latValue = data['lat'];
        final lngValue = data['lng'];
        
        // Validate lat/lng are numbers
        if (latValue is! num || lngValue is! num) return;
        
        final lat = latValue.toDouble();
        final lng = lngValue.toDouble();
        
        // Validate coordinate ranges
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
        
        final newPos = LatLng(lat, lng);

        if (mounted) {
          setState(() {
            _currentPosition = newPos;
            _hasReceivedData = true;
            
            // Update path for moving mode
            if (widget.config.isMovingMode) {
              if (_path.isEmpty || _path.last != _currentPosition) {
                _path.add(_currentPosition);
              }
            }
          });
          
          // Camera operations after setState
          _updateCamera();
        }
      }
    } catch (e) {
      debugPrint('MapPanel: Error parsing GPS data: $e');
    }
  }

  void _updateCamera() {
    if (!_mapReady) return;
    
    try {
      if (widget.config.isMovingMode) {
        // Smooth animation for moving mode
        _mapController.move(_currentPosition, _mapController.camera.zoom);
      } else if (_isFirstUpdate) {
        // Jump to position on first update for static mode
        _mapController.move(_currentPosition, 15.0);
        _isFirstUpdate = false;
      }
    } catch (e) {
      debugPrint('MapPanel: Camera update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
              onMapReady: () {
                _mapReady = true;
                if (_hasReceivedData) {
                  _updateCamera();
                }
              },
            ),
            children: [
              // OpenStreetMap Tile Layer - FREE, no API key needed!
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.valiotdashboard',
                maxZoom: 19,
              ),
              
              // Path polyline for moving mode
              if (widget.config.isMovingMode && _path.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _path,
                      color: widget.config.color,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              
              // Marker layer
              if (_hasReceivedData)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.config.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.config.isMovingMode 
                              ? Icons.navigation 
                              : Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // Title overlay
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.config.isMovingMode ? Icons.navigation : Icons.location_on,
                  size: 16,
                  color: widget.config.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.config.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.config.isMovingMode) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.config.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: widget.config.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Coordinates display
        if (_hasReceivedData)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_currentPosition.latitude.toStringAsFixed(5)}, ${_currentPosition.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        
        // Loading indicator when no data yet
        if (!_hasReceivedData)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.config.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for GPS data...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                    if (widget.config.subscribeTopic != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.config.subscribeTopic!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.disabledColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
