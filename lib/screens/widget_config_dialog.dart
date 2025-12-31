import 'package:flutter/material.dart';
import '../models/panel_widget_config.dart';
import '../utils/icon_helper.dart';

class WidgetConfigDialog extends StatefulWidget {
  final PanelWidgetConfig? initialConfig;

  const WidgetConfigDialog({super.key, this.initialConfig});

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subscribeTopicController;
  late TextEditingController _publishTopicController;
  late TextEditingController _onPayloadController;
  late TextEditingController _offPayloadController;
  late TextEditingController _minValueController;
  late TextEditingController _maxValueController;
  late TextEditingController _unitController;

  WidgetType _selectedType = WidgetType.toggle;
  int _qos = 0;
  Color _selectedColor = Colors.blue;
  int? _selectedIconCodePoint;
  bool _colorInitializedFromTheme = false;
  int? _mapMarkerIcon;  // 1-21 untuk icon pack Map Tracker

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialConfig?.title ?? '');
    _subscribeTopicController = TextEditingController(text: widget.initialConfig?.subscribeTopic ?? '');
    _publishTopicController = TextEditingController(text: widget.initialConfig?.publishTopic ?? '');
    _onPayloadController = TextEditingController(text: widget.initialConfig?.onPayload ?? 'ON');
    _offPayloadController = TextEditingController(text: widget.initialConfig?.offPayload ?? 'OFF');
    _minValueController = TextEditingController(text: widget.initialConfig?.minValue?.toString() ?? '0');
    _maxValueController = TextEditingController(text: widget.initialConfig?.maxValue?.toString() ?? '100');
    _unitController = TextEditingController(text: widget.initialConfig?.unit ?? '');

    if (widget.initialConfig != null) {
      _selectedType = widget.initialConfig!.type;
      _qos = widget.initialConfig!.qos;
      _selectedColor = widget.initialConfig!.color;
      _selectedIconCodePoint = widget.initialConfig!.iconCodePoint;
      _mapMarkerIcon = widget.initialConfig!.mapMarkerIcon;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subscribeTopicController.dispose();
    _publishTopicController.dispose();
    _onPayloadController.dispose();
    _offPayloadController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_colorInitializedFromTheme && widget.initialConfig == null) {
      _selectedColor = Theme.of(context).colorScheme.primary;
      _colorInitializedFromTheme = true;
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.initialConfig == null ? 'Add Widget' : 'Edit Widget',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<WidgetType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Widget Type',
                      border: OutlineInputBorder(),
                    ),
                    items: WidgetType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getWidgetTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_needsSubscribeTopic())
                    TextFormField(
                      controller: _subscribeTopicController,
                      decoration: const InputDecoration(
                        labelText: 'Subscribe Topic',
                        border: OutlineInputBorder(),
                        hintText: 'sensor/temperature',
                      ),
                      validator: (value) {
                        if (_needsSubscribeTopic() && (value == null || value.isEmpty)) {
                          return 'Subscribe topic wajib diisi';
                        }
                        return null;
                      },
                    ),
                  if (_needsSubscribeTopic()) const SizedBox(height: 16),
                  if (_needsPublishTopic())
                    TextFormField(
                      controller: _publishTopicController,
                      decoration: const InputDecoration(
                        labelText: 'Publish Topic',
                        border: OutlineInputBorder(),
                        hintText: 'device/switch',
                      ),
                      validator: (value) {
                        if (_needsPublishTopic() && (value == null || value.isEmpty)) {
                          return 'Please enter a publish topic';
                        }
                        return null;
                      },
                    ),
                  if (_needsPublishTopic()) const SizedBox(height: 16),
                  if (_selectedType == WidgetType.toggle) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _onPayloadController,
                            decoration: const InputDecoration(
                              labelText: 'ON Payload',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Payload ON tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _offPayloadController,
                            decoration: const InputDecoration(
                              labelText: 'OFF Payload',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Payload OFF tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedType == WidgetType.button) ...[
                    TextFormField(
                      controller: _onPayloadController,
                      decoration: const InputDecoration(
                        labelText: 'Payload',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Payload tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedType == WidgetType.gauge || _selectedType == WidgetType.lineChart || _selectedType == WidgetType.slider) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minValueController,
                            decoration: const InputDecoration(
                              labelText: 'Min Value',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxValueController,
                            decoration: const InputDecoration(
                              labelText: 'Max Value',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (optional)',
                        border: OutlineInputBorder(),
                        hintText: '°C, %, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Map Marker Icon picker
                  if (_selectedType == WidgetType.map) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Marker Icon (Mode Tracking):'),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih icon yang akan ditampilkan saat mode realtime',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 21,
                            itemBuilder: (context, index) {
                              final iconNumber = index + 1;
                              final isSelected = _mapMarkerIcon == iconNumber;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _mapMarkerIcon = isSelected ? null : iconNumber;
                                  });
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? _selectedColor.withOpacity(0.2) 
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/icon/$iconNumber.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            '$iconNumber',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? _selectedColor : Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_mapMarkerIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Icon $_mapMarkerIcon dipilih',
                              style: TextStyle(
                                color: _selectedColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<int>(
                    value: _qos,
                    decoration: const InputDecoration(
                      labelText: 'QoS Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('0 - At most once')),
                      DropdownMenuItem(value: 1, child: Text('1 - At least once')),
                      DropdownMenuItem(value: 2, child: Text('2 - Exactly once')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _qos = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Color:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal, Colors.pink, Colors.indigo].map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == color ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewCard(),
                  const SizedBox(height: 16),
                  if (_selectedType == WidgetType.toggle || _selectedType == WidgetType.button) ...[
                    const Text('Icon (optional):'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: IconHelper.availableIcons.map((iconData) {
                        return _buildIconOption(iconData.codePoint, iconData);
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveWidget,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _needsSubscribeTopic() {
    return _selectedType == WidgetType.toggle ||
        _selectedType == WidgetType.gauge ||
        _selectedType == WidgetType.lineChart ||
        _selectedType == WidgetType.map ||
        _selectedType == WidgetType.slider;
  }

  bool _needsPublishTopic() {
    return _selectedType == WidgetType.toggle || 
           _selectedType == WidgetType.button ||
           _selectedType == WidgetType.slider;
  }

  String _getWidgetTypeName(WidgetType type) {
    switch (type) {
      case WidgetType.toggle:
        return 'Toggle Switch';
      case WidgetType.button:
        return 'Button';
      case WidgetType.gauge:
        return 'Gauge';
      case WidgetType.lineChart:
        return 'Line Chart';
      case WidgetType.text:
        return 'Text Display';
      case WidgetType.map:
        return 'Map Tracker';
      case WidgetType.slider:
        return 'Slider Control';
      case WidgetType.alarm:
        return 'Alarm Panel';
    }
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _selectedColor.withOpacity(0.15),
              child: Icon(
                _selectedIconCodePoint != null ? IconData(_selectedIconCodePoint!, fontFamily: 'MaterialIcons') : Icons.widgets,
                color: _selectedColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text.isEmpty ? 'Preview title' : _titleController.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getWidgetTypeName(_selectedType),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'QoS $_qos',
                style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOption(int codePoint, IconData iconData) {
    final isSelected = _selectedIconCodePoint == codePoint;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIconCodePoint = isSelected ? null : codePoint;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          iconData,
          color: isSelected ? _selectedColor : Colors.grey,
        ),
      ),
    );
  }

  void _saveWidget() {
    if (_formKey.currentState!.validate()) {
      final minValue = double.tryParse(_minValueController.text) ?? 0;
      final maxValue = double.tryParse(_maxValueController.text) ?? 100;
      if (minValue >= maxValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Min value harus lebih kecil dari Max value'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final config = PanelWidgetConfig(
        id: widget.initialConfig?.id,
        title: _titleController.text,
        type: _selectedType,
        subscribeTopic: _subscribeTopicController.text.isEmpty ? null : _subscribeTopicController.text,
        publishTopic: _publishTopicController.text.isEmpty ? null : _publishTopicController.text,
        onPayload: _onPayloadController.text,
        offPayload: _offPayloadController.text,
        qos: _qos,
        colorValue: _selectedColor.value,
        iconCodePoint: _selectedIconCodePoint,
        minValue: minValue,
        maxValue: maxValue,
        unit: _unitController.text.isEmpty ? null : _unitController.text,
        isMovingMode: false, // Default: static mode, can be toggled from panel
        idleTimeoutSeconds: 10, // Default timeout
        mapMarkerIcon: _mapMarkerIcon,
        x: widget.initialConfig?.x ?? 0,
        y: widget.initialConfig?.y ?? 0,
        width: widget.initialConfig?.width ?? 1,
        height: widget.initialConfig?.height ?? 1,
      );

      Navigator.pop(context, config);
    }
  }
}