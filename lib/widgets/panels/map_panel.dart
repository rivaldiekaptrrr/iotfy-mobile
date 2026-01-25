import 'dart:async';
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
  
  // Local moving mode state - dapat di-toggle langsung dari UI
  late bool _isMovingMode;
  
  // LRU Path Management
  static const int _maxPathPoints = 500;
  static const double _minDistanceMeters = 5.0; // Minimum jarak untuk menambah point baru
  
  // Idle timeout
  Timer? _idleTimer;
  bool _showResetIndicator = false;
  
  // GPS Data tambahan
  double _speedKmh = 0.0;
  double _course = 0.0;  // Heading dalam derajat (0-360)
  double _altitude = 0.0;
  int _satellites = 0;
  double _hdop = 0.0;
  bool _hasFix = false;
  String? _timestamp;
  
  // Historical Playback Mode
  List<LatLng> _historyPath = [];  // Simpan path terakhir untuk playback
  bool _isPlayingHistory = false;  // Apakah sedang memutar animasi
  int _playbackIndex = 0;  // Index posisi animasi saat ini
  Timer? _playbackTimer;  // Timer untuk animasi
  static const int _playbackIntervalMs = 200;  // Interval animasi (ms)
  bool _isIdle = false;  // Status idle (setelah timeout)

  @override
  void initState() {
    super.initState();
    _isMovingMode = widget.config.isMovingMode; // Inisialisasi dari config
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

  void _startIdleTimer() {
    _idleTimer?.cancel();
    
    if (!_isMovingMode) return;
    if (widget.config.idleTimeoutSeconds <= 0) return;
    
    _idleTimer = Timer(
      Duration(seconds: widget.config.idleTimeoutSeconds),
      _onIdleTimeout,
    );
  }

  void _onIdleTimeout() {
    if (!mounted) return;
    if (!_isMovingMode) return;
    
    setState(() {
      // Simpan path ke history sebelum clear (untuk playback)
      if (_path.length > 1) {
        _historyPath = List<LatLng>.from(_path);
      }
      _path.clear();
      _isIdle = true;
      _showResetIndicator = true;
    });
    
    // Hide indicator after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showResetIndicator = false;
        });
      }
    });
  }

  // Toggle moving mode dari UI
  void _toggleMovingMode() {
    setState(() {
      _isMovingMode = !_isMovingMode;
      if (!_isMovingMode) {
        // Clear path ketika switch ke static mode
        _path.clear();
        _idleTimer?.cancel();
        _stopPlayback();
      } else {
        // Start idle timer ketika switch ke moving mode
        _startIdleTimer();
      }
    });
  }

  // ============ HISTORICAL PLAYBACK METHODS ============
  
  void _startPlayback() {
    if (_historyPath.length < 2) return;
    
    setState(() {
      _isPlayingHistory = true;
      _playbackIndex = 0;
    });
    
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: _playbackIntervalMs),
      _onPlaybackTick,
    );
  }
  
  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (mounted) {
      setState(() {
        _isPlayingHistory = false;
        _playbackIndex = 0;
      });
    }
  }
  
  void _onPlaybackTick(Timer timer) {
    if (!mounted || _historyPath.isEmpty) {
      _stopPlayback();
      return;
    }
    
    setState(() {
      _playbackIndex++;
      // Loop kembali ke awal
      if (_playbackIndex >= _historyPath.length) {
        _playbackIndex = 0;
      }
    });
    
    // Move camera to follow playback position
    if (_mapReady && _playbackIndex < _historyPath.length) {
      _mapController.move(_historyPath[_playbackIndex], _mapController.camera.zoom);
    }
  }
  
  // Posisi marker saat playback
  LatLng get _playbackPosition {
    if (_historyPath.isEmpty) return _currentPosition;
    if (_playbackIndex >= _historyPath.length) return _historyPath.last;
    return _historyPath[_playbackIndex];
  }

  // Hitung jarak antara dua koordinat dalam meter
  double _calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  // Build marker widget - menggunakan icon PNG custom atau default icon
  Widget _buildMarkerWidget() {
    final bool useCustomIcon = (_isMovingMode || _isPlayingHistory) && 
                                widget.config.mapMarkerIcon != null;
    
    // Jika menggunakan custom icon PNG
    if (useCustomIcon) {
      // Tampilkan gambar apa adanya tanpa background/shadow kotak
      return Image.asset(
        'assets/icon/${widget.config.mapMarkerIcon}.png',
        width: 56,
        height: 56,
        fit: BoxFit.contain, // Gunakan contain agar gambar utuh tidak terpotong
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset assets/icon/${widget.config.mapMarkerIcon}.png: $error');
          return _buildDefaultMarkerIcon();
        },
      );
    }
    
    // Default marker icon (untuk mode statis atau tanpa custom icon)
    return _buildDefaultMarkerIcon();
  }
  
  Widget _buildDefaultMarkerIcon() {
    return Container(
      decoration: BoxDecoration(
        color: _isPlayingHistory 
            ? Colors.orange 
            : widget.config.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white, 
          width: _isPlayingHistory ? 4 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _isMovingMode || _isPlayingHistory
                ? Icons.two_wheeler
                : Icons.location_on,
            color: Colors.white,
            size: 28,
          ),
          // Speed indicator ring
          if (_isMovingMode && _speedKmh > 0 && !_isPlayingHistory)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _speedKmh > 50 ? Colors.red : (_speedKmh > 20 ? Colors.orange : Colors.green),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.subscribeTopic != oldWidget.config.subscribeTopic) {
      _subscribeToTopic();
    }
    // Sync isMovingMode jika config berubah dari luar (optional)
    if (widget.config.isMovingMode != oldWidget.config.isMovingMode) {
      _isMovingMode = widget.config.isMovingMode;
      if (!_isMovingMode) {
        _path.clear();
        _idleTimer?.cancel();
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
    _idleTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _handleMessage(String payload) {
    if (!mounted) return;
    
    try {
      final data = json.decode(payload);
      if (data is Map<String, dynamic> &&
          data.containsKey('lat') &&
          (data.containsKey('lon') || data.containsKey('lng'))) {
        final latValue = data['lat'];
        // Support both 'lon' dan 'lng' untuk kompatibilitas
        final lonValue = data['lon'] ?? data['lng'];
        
        // Validate lat/lon are numbers
        if (latValue is! num || lonValue is! num) return;
        
        final lat = latValue.toDouble();
        final lon = lonValue.toDouble();
        
        // Validate coordinate ranges
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return;
        
        final newPos = LatLng(lat, lon);

        if (mounted) {
          // Stop playback dan reset idle status saat ada data baru
          if (_isPlayingHistory || _isIdle) {
            _stopPlayback();
            _historyPath.clear();  // Clear history karena tracking baru dimulai
          }
          
          setState(() {
            _currentPosition = newPos;
            _hasReceivedData = true;
            _isIdle = false;  // Reset idle status
            
            // Parse GPS data tambahan
            if (data.containsKey('speed_kmh') && data['speed_kmh'] is num) {
              _speedKmh = (data['speed_kmh'] as num).toDouble();
            }
            if (data.containsKey('course') && data['course'] is num) {
              _course = (data['course'] as num).toDouble();
            }
            if (data.containsKey('altitude') && data['altitude'] is num) {
              _altitude = (data['altitude'] as num).toDouble();
            }
            if (data.containsKey('satellites') && data['satellites'] is num) {
              _satellites = (data['satellites'] as num).toInt();
            }
            if (data.containsKey('hdop') && data['hdop'] is num) {
              _hdop = (data['hdop'] as num).toDouble();
            }
            if (data.containsKey('fix')) {
              _hasFix = data['fix'] == true;
            }
            if (data.containsKey('timestamp') && data['timestamp'] is String) {
              _timestamp = data['timestamp'] as String;
            }
            
            // Update path for moving mode dengan distance threshold dan LRU
            if (_isMovingMode) {
              bool shouldAddPoint = false;
              
              if (_path.isEmpty) {
                shouldAddPoint = true;
              } else {
                // Hanya tambah point jika jarak >= minimum threshold
                final distance = _calculateDistance(_path.last, _currentPosition);
                if (distance >= _minDistanceMeters) {
                  shouldAddPoint = true;
                }
              }
              
              if (shouldAddPoint) {
                _path.add(_currentPosition);
                
                // LRU Strategy: hapus point terlama jika melebihi max
                while (_path.length > _maxPathPoints) {
                  _path.removeAt(0);
                }
              }
            }
          });
          
          // Reset idle timer on new data
          _startIdleTimer();
          
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
      if (_isMovingMode) {
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

  void _openFullscreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenMapView(
          config: widget.config,
          currentPosition: _currentPosition,
          path: List.from(_path),
          hasData: _hasReceivedData,
          isMovingMode: _isMovingMode, // Pass current moving mode state
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Hero(
            tag: '${widget.config.id}_map',
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
                
                // Path polyline - untuk tracking atau playback
                if ((_isMovingMode && _path.length > 1) || (_isPlayingHistory && _historyPath.length > 1))
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _isPlayingHistory ? _historyPath : _path,
                        color: _isPlayingHistory 
                            ? widget.config.color.withOpacity(0.6) 
                            : widget.config.color,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                
                // History path trail saat playback (menunjukkan progress)
                if (_isPlayingHistory && _playbackIndex > 0)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _historyPath.sublist(0, _playbackIndex + 1),
                        color: widget.config.color,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                
                // Marker layer - posisi berdasarkan mode (live atau playback)
                if (_hasReceivedData || _isPlayingHistory)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _isPlayingHistory ? _playbackPosition : _currentPosition,
                        width: 56,
                        height: 56,
                        child: Transform.rotate(
                          angle: (_isMovingMode || _isPlayingHistory) ? (_course * 3.14159265359 / 180) : 0,
                          child: _buildMarkerWidget(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        // Title overlay
        Positioned(
          top: 8,
          left: 8,
          right: 136, // Leave space for buttons
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
                  _isMovingMode || _isPlayingHistory 
                      ? Icons.two_wheeler  // Ikon motor
                      : Icons.location_on,
                  size: 16,
                  color: _isPlayingHistory ? Colors.orange : widget.config.color,
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
                // Status badge
                if (_isMovingMode || _isPlayingHistory) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isPlayingHistory 
                          ? Colors.orange.withOpacity(0.2) 
                          : widget.config.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isPlayingHistory) ...[
                          const Icon(Icons.play_arrow, size: 10, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            'REPLAY',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: widget.config.color,
                            ),
                          ),
                          if (_path.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${_path.length})',
                              style: TextStyle(
                                fontSize: 8,
                                color: widget.config.color.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Playback button - muncul ketika ada history dan idle
        if (_isIdle && _historyPath.length > 1)
          Positioned(
            top: 8,
            right: 88, // Sebelah toggle button
            child: Material(
              color: _isPlayingHistory 
                  ? Colors.orange 
                  : theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              child: InkWell(
                onTap: _isPlayingHistory ? _stopPlayback : _startPlayback,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isPlayingHistory ? Icons.stop : Icons.play_arrow,
                    size: 20,
                    color: _isPlayingHistory 
                        ? Colors.white 
                        : Colors.orange,
                  ),
                ),
              ),
            ),
          ),

        // Mode toggle button
        Positioned(
          top: 8,
          right: 48,
          child: Material(
            color: _isMovingMode 
                ? widget.config.color.withOpacity(0.9)
                : theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: _toggleMovingMode,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isMovingMode ? Icons.timeline : Icons.pin_drop,
                  size: 18,
                  color: _isMovingMode 
                      ? Colors.white 
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        // Fullscreen button
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: _openFullscreenMap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fullscreen,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        
        // GPS Info display
        if (_hasReceivedData)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coordinates
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currentPosition.latitude.toStringAsFixed(5)}, ${_currentPosition.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Speed
                            Icon(Icons.speed, color: Colors.white70, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${_speedKmh.toStringAsFixed(widget.config.decimalPlaces)} km/h',
                              style: const TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                            const SizedBox(width: 8),
                            // Heading
                            Icon(Icons.explore, color: Colors.white70, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${_course.toStringAsFixed(widget.config.decimalPlaces)}°',
                              style: const TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                            const SizedBox(width: 8),
                            // Satellites
                            Icon(Icons.satellite_alt, color: _hasFix ? Colors.green : Colors.orange, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '$_satellites',
                              style: TextStyle(color: _hasFix ? Colors.green : Colors.orange, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Path reset indicator
        if (_showResetIndicator)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Path reset - idle timeout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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

// ============================================================================
// FULLSCREEN MAP VIEW
// ============================================================================

class FullscreenMapView extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;
  final LatLng currentPosition;
  final List<LatLng> path;
  final bool hasData;
  final bool isMovingMode; // Receive from parent

  const FullscreenMapView({
    super.key,
    required this.config,
    required this.currentPosition,
    required this.path,
    required this.hasData,
    required this.isMovingMode,
  });

  @override
  ConsumerState<FullscreenMapView> createState() => _FullscreenMapViewState();
}

class _FullscreenMapViewState extends ConsumerState<FullscreenMapView> {
  late final MapController _mapController;
  late LatLng _currentPosition;
  late List<LatLng> _path;
  late bool _hasReceivedData;
  ProviderSubscription<AsyncValue<app_mqtt.MqttMessageData>>? _messageSub;
  bool _mapReady = false;
  bool _followMode = true;
  
  // Local moving mode state - dapat di-toggle langsung dari UI
  late bool _isMovingMode;
  
  // LRU Path Management (same as MapPanel)
  static const int _maxPathPoints = 500;
  static const double _minDistanceMeters = 5.0;
  
  // Idle timeout
  Timer? _idleTimer;
  bool _showResetIndicator = false;
  
  // GPS Data tambahan
  double _speedKmh = 0.0;
  double _course = 0.0;
  double _altitude = 0.0;
  int _satellites = 0;
  double _hdop = 0.0;
  bool _hasFix = false;
  String? _timestamp;
  
  // Historical Playback Mode
  List<LatLng> _historyPath = [];
  bool _isPlayingHistory = false;
  int _playbackIndex = 0;
  Timer? _playbackTimer;
  static const int _playbackIntervalMs = 200;
  bool _isIdle = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = widget.currentPosition;
    _path = List.from(widget.path);
    _hasReceivedData = widget.hasData;
    _isMovingMode = widget.isMovingMode; // Initialize from parent
    _followMode = _isMovingMode;
    _setupMessageListener();
    
    // Start idle timer if we have data
    if (_hasReceivedData && _isMovingMode) {
      _startIdleTimer();
    }
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

  void _startIdleTimer() {
    _idleTimer?.cancel();
    
    if (!_isMovingMode) return;
    if (widget.config.idleTimeoutSeconds <= 0) return;
    
    _idleTimer = Timer(
      Duration(seconds: widget.config.idleTimeoutSeconds),
      _onIdleTimeout,
    );
  }

  void _onIdleTimeout() {
    if (!mounted) return;
    if (!_isMovingMode) return;
    
    setState(() {
      // Simpan path ke history sebelum clear
      if (_path.length > 1) {
        _historyPath = List<LatLng>.from(_path);
      }
      _path.clear();
      _isIdle = true;
      _showResetIndicator = true;
    });
    
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.white),
            const SizedBox(width: 8),
            Text('Path reset - tidak ada data selama ${widget.config.idleTimeoutSeconds} detik'),
            if (_historyPath.length > 1) ...[
              const SizedBox(width: 8),
              const Text('| Tap ▶ untuk replay', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Hide indicator after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showResetIndicator = false;
        });
      }
    });
  }

  // Toggle moving mode dari UI
  void _toggleMovingMode() {
    setState(() {
      _isMovingMode = !_isMovingMode;
      if (!_isMovingMode) {
        // Clear path ketika switch ke static mode
        _path.clear();
        _idleTimer?.cancel();
        _followMode = false;
        _stopPlayback();
      } else {
        // Start idle timer dan follow mode ketika switch ke moving mode
        _followMode = true;
        _startIdleTimer();
      }
    });
    
    // Tampilkan feedback ke user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isMovingMode ? Icons.two_wheeler : Icons.pin_drop,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(_isMovingMode ? 'Mode Tracking aktif' : 'Mode Statis aktif'),
          ],
        ),
        backgroundColor: _isMovingMode ? widget.config.color : Colors.grey,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Hitung jarak antara dua koordinat dalam meter
  double _calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  // ============ HISTORICAL PLAYBACK METHODS ============
  
  void _startPlayback() {
    if (_historyPath.length < 2) return;
    
    setState(() {
      _isPlayingHistory = true;
      _playbackIndex = 0;
    });
    
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: _playbackIntervalMs),
      _onPlaybackTick,
    );
  }
  
  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (mounted) {
      setState(() {
        _isPlayingHistory = false;
        _playbackIndex = 0;
      });
    }
  }
  
  void _onPlaybackTick(Timer timer) {
    if (!mounted || _historyPath.isEmpty) {
      _stopPlayback();
      return;
    }
    
    setState(() {
      _playbackIndex++;
      if (_playbackIndex >= _historyPath.length) {
        _playbackIndex = 0;
      }
    });
    
    if (_mapReady && _playbackIndex < _historyPath.length) {
      _mapController.move(_historyPath[_playbackIndex], _mapController.camera.zoom);
    }
  }
  
  LatLng get _playbackPosition {
    if (_historyPath.isEmpty) return _currentPosition;
    if (_playbackIndex >= _historyPath.length) return _historyPath.last;
    return _historyPath[_playbackIndex];
  }

  // Build marker widget - menggunakan icon PNG custom atau default icon
  Widget _buildMarkerWidget() {
    final bool useCustomIcon = (_isMovingMode || _isPlayingHistory) && 
                                widget.config.mapMarkerIcon != null;
    
    if (useCustomIcon) {
      return Image.asset(
        'assets/icon/${widget.config.mapMarkerIcon}.png',
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset assets/icon/${widget.config.mapMarkerIcon}.png: $error');
          return _buildDefaultMarkerIcon();
        },
      );
    }
    
    return _buildDefaultMarkerIcon();
  }
  
  Widget _buildDefaultMarkerIcon() {
    return Container(
      decoration: BoxDecoration(
        color: _isPlayingHistory 
            ? Colors.orange 
            : widget.config.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white, 
          width: _isPlayingHistory ? 5 : 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _isMovingMode || _isPlayingHistory
                ? Icons.two_wheeler
                : Icons.location_on,
            color: Colors.white,
            size: 30,
          ),
          if (_isMovingMode && _speedKmh > 0 && !_isPlayingHistory)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _speedKmh > 50 ? Colors.red : (_speedKmh > 20 ? Colors.orange : Colors.green),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageSub?.close();
    _mapController.dispose();
    _idleTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _handleMessage(String payload) {
    if (!mounted) return;
    
    try {
      final data = json.decode(payload);
      if (data is Map<String, dynamic> &&
          data.containsKey('lat') &&
          (data.containsKey('lon') || data.containsKey('lng'))) {
        final latValue = data['lat'];
        final lonValue = data['lon'] ?? data['lng'];
        
        if (latValue is! num || lonValue is! num) return;
        
        final lat = latValue.toDouble();
        final lon = lonValue.toDouble();
        
        if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return;
        
        final newPos = LatLng(lat, lon);

        if (mounted) {
          // Stop playback dan reset idle saat ada data baru
          if (_isPlayingHistory || _isIdle) {
            _stopPlayback();
            _historyPath.clear();
          }
          
          setState(() {
            _currentPosition = newPos;
            _hasReceivedData = true;
            _isIdle = false;
            
            // Parse GPS data tambahan
            if (data.containsKey('speed_kmh') && data['speed_kmh'] is num) {
              _speedKmh = (data['speed_kmh'] as num).toDouble();
            }
            if (data.containsKey('course') && data['course'] is num) {
              _course = (data['course'] as num).toDouble();
            }
            if (data.containsKey('altitude') && data['altitude'] is num) {
              _altitude = (data['altitude'] as num).toDouble();
            }
            if (data.containsKey('satellites') && data['satellites'] is num) {
              _satellites = (data['satellites'] as num).toInt();
            }
            if (data.containsKey('hdop') && data['hdop'] is num) {
              _hdop = (data['hdop'] as num).toDouble();
            }
            if (data.containsKey('fix')) {
              _hasFix = data['fix'] == true;
            }
            if (data.containsKey('timestamp') && data['timestamp'] is String) {
              _timestamp = data['timestamp'] as String;
            }
            
            // Update path for moving mode dengan distance threshold dan LRU
            if (_isMovingMode) {
              bool shouldAddPoint = false;
              
              if (_path.isEmpty) {
                shouldAddPoint = true;
              } else {
                // Hanya tambah point jika jarak >= minimum threshold
                final distance = _calculateDistance(_path.last, _currentPosition);
                if (distance >= _minDistanceMeters) {
                  shouldAddPoint = true;
                }
              }
              
              if (shouldAddPoint) {
                _path.add(_currentPosition);
                
                // LRU Strategy: hapus point terlama jika melebihi max
                while (_path.length > _maxPathPoints) {
                  _path.removeAt(0);
                }
              }
            }
          });
          
          // Reset idle timer on new data
          _startIdleTimer();
          
          if (_followMode && _mapReady) {
            _mapController.move(_currentPosition, _mapController.camera.zoom);
          }
        }
      }
    } catch (e) {
      debugPrint('FullscreenMap: Error parsing GPS data: $e');
    }
  }

  void _centerOnMarker() {
    if (_mapReady && _hasReceivedData) {
      _mapController.move(_currentPosition, 16.0);
      setState(() {
        _followMode = true;
      });
    }
  }

  void _zoomIn() {
    if (_mapReady) {
      final currentZoom = _mapController.camera.zoom;
      if (currentZoom < 19) {
        _mapController.move(_mapController.camera.center, currentZoom + 1);
      }
    }
  }

  void _zoomOut() {
    if (_mapReady) {
      final currentZoom = _mapController.camera.zoom;
      if (currentZoom > 3) {
        _mapController.move(_mapController.camera.center, currentZoom - 1);
      }
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              _isMovingMode || _isPlayingHistory 
                  ? Icons.two_wheeler  // Ikon motor
                  : Icons.location_on,
              size: 20,
              color: _isPlayingHistory ? Colors.orange : widget.config.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.config.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status badge
            if (_isMovingMode || _isPlayingHistory)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isPlayingHistory 
                      ? Colors.orange.withOpacity(0.2)
                      : widget.config.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isPlayingHistory) ...[
                      const Icon(Icons.play_arrow, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'REPLAY ${_playbackIndex + 1}/${_historyPath.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.config.color,
                        ),
                      ),
                      if (_path.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${_path.length})',
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.config.color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Playback button - muncul ketika ada history dan idle
          if (_isIdle && _historyPath.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _isPlayingHistory 
                    ? Colors.orange 
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _isPlayingHistory ? _stopPlayback : _startPlayback,
                icon: Icon(
                  _isPlayingHistory ? Icons.stop : Icons.play_arrow,
                  color: _isPlayingHistory ? Colors.white : Colors.orange,
                ),
                tooltip: _isPlayingHistory ? 'Stop Replay' : 'Play History',
              ),
            ),
          // Mode toggle button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isMovingMode 
                  ? widget.config.color.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _toggleMovingMode,
              icon: Icon(
                _isMovingMode ? Icons.timeline : Icons.pin_drop,
                color: _isMovingMode 
                    ? widget.config.color 
                    : theme.colorScheme.onSurface,
              ),
              tooltip: _isMovingMode ? 'Switch to Static' : 'Switch to Tracking',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Hero(
            tag: '${widget.config.id}_map',
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 16.0,
                onMapReady: () {
                  _mapReady = true;
                },
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    // User interacted with map, disable auto-follow
                    setState(() {
                      _followMode = false;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.valiotdashboard',
                  maxZoom: 19,
                ),
                
                // Path polyline - untuk tracking atau playback
                if ((_isMovingMode && _path.length > 1) || (_isPlayingHistory && _historyPath.length > 1))
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _isPlayingHistory ? _historyPath : _path,
                        color: _isPlayingHistory 
                            ? widget.config.color.withOpacity(0.6) 
                            : widget.config.color,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                
                // History path trail saat playback
                if (_isPlayingHistory && _playbackIndex > 0)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _historyPath.sublist(0, _playbackIndex + 1),
                        color: widget.config.color,
                        strokeWidth: 6.0,
                      ),
                    ],
                  ),
                
                // Marker - posisi berdasarkan mode (live atau playback)
                if (_hasReceivedData || _isPlayingHistory)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _isPlayingHistory ? _playbackPosition : _currentPosition,
                        width: 64,
                        height: 64,
                        child: Transform.rotate(
                          angle: (_isMovingMode || _isPlayingHistory) ? (_course * 3.14159265359 / 180) : 0,
                          child: _buildMarkerWidget(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // GPS Info display - Full details
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coordinates row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coordinates',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _hasReceivedData 
                                  ? '${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}'
                                  : 'Waiting for data...',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Fix status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hasFix ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasFix ? Icons.gps_fixed : Icons.gps_not_fixed,
                              size: 14,
                              color: _hasFix ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _hasFix ? 'FIX' : 'NO FIX',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _hasFix ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isMovingMode && _path.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.config.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_path.length} pts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.config.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // GPS Stats row
                  Row(
                    children: [
                      // Speed
                      _buildInfoChip(
                        icon: Icons.speed,
                        label: '${_speedKmh.toStringAsFixed(widget.config.decimalPlaces)} km/h',
                        color: _speedKmh > 50 ? Colors.red : (_speedKmh > 20 ? Colors.orange : Colors.green),
                      ),
                      const SizedBox(width: 8),
                      // Heading
                      _buildInfoChip(
                        icon: Icons.explore,
                        label: '${_course.toStringAsFixed(widget.config.decimalPlaces)}°',
                        color: widget.config.color,
                      ),
                      const SizedBox(width: 8),
                      // Altitude
                      _buildInfoChip(
                        icon: Icons.terrain,
                        label: '${_altitude.toStringAsFixed(widget.config.decimalPlaces)} m',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      // Satellites
                      _buildInfoChip(
                        icon: Icons.satellite_alt,
                        label: '$_satellites sat',
                        color: _satellites >= 8 ? Colors.green : (_satellites >= 4 ? Colors.orange : Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Reset indicator
          if (_showResetIndicator)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Path reset - idle ${widget.config.idleTimeoutSeconds}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Map controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // Follow mode indicator
                if (_isMovingMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _followMode ? widget.config.color : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _centerOnMarker,
                      icon: Icon(
                        _followMode ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _followMode ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      tooltip: _followMode ? 'Following' : 'Tap to follow',
                    ),
                  ),
                
                // Zoom controls
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: _zoomIn,
                        icon: const Icon(Icons.add),
                        tooltip: 'Zoom in',
                      ),
                      Container(
                        height: 1,
                        width: 24,
                        color: theme.dividerColor,
                      ),
                      IconButton(
                        onPressed: _zoomOut,
                        icon: const Icon(Icons.remove),
                        tooltip: 'Zoom out',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Center on marker
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _centerOnMarker,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Center on marker',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
