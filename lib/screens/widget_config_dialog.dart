import 'package:flutter/material.dart';
import '../models/panel_widget_config.dart';
import '../utils/icon_helper.dart';

class WidgetConfigDialog extends StatefulWidget {
  final PanelWidgetConfig? initialConfig;
  final WidgetType? preSelectedType;

  const WidgetConfigDialog({
    super.key,
    this.initialConfig,
    this.preSelectedType,
  });

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
  late TextEditingController _warningThresholdController;
  late TextEditingController _criticalThresholdController;
  late TextEditingController _optionsController;
  late TextEditingController _jsonPathController;
  late TextEditingController _jsonPatternController;

  WidgetType _selectedType = WidgetType.toggle;
  int _qos = 0;
  Color _selectedColor = Colors.blue;
  int? _selectedIconCodePoint;
  bool _colorInitializedFromTheme = false;
  int? _mapMarkerIcon; // 1-21 untuk icon pack Map Tracker
  bool _isJsonPayload = false;
  int _decimalPlaces = 1; // 0 = integer, 1-2 = float

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialConfig?.title ?? '',
    );
    _subscribeTopicController = TextEditingController(
      text: widget.initialConfig?.subscribeTopic ?? '',
    );
    _publishTopicController = TextEditingController(
      text: widget.initialConfig?.publishTopic ?? '',
    );
    _onPayloadController = TextEditingController(
      text: widget.initialConfig?.onPayload ?? 'ON',
    );
    _offPayloadController = TextEditingController(
      text: widget.initialConfig?.offPayload ?? 'OFF',
    );
    _minValueController = TextEditingController(
      text: widget.initialConfig?.minValue?.toString() ?? '0',
    );
    _maxValueController = TextEditingController(
      text: widget.initialConfig?.maxValue?.toString() ?? '100',
    );
    _unitController = TextEditingController(
      text: widget.initialConfig?.unit ?? '',
    );
    _warningThresholdController = TextEditingController(
      text: widget.initialConfig?.warningThreshold?.toString() ?? '',
    );
    _criticalThresholdController = TextEditingController(
      text: widget.initialConfig?.criticalThreshold?.toString() ?? '',
    );
    _optionsController = TextEditingController(
      text: widget.initialConfig?.options?.join(',') ?? '',
    );
    _jsonPathController = TextEditingController(
      text: widget.initialConfig?.jsonPath ?? '',
    );
    _jsonPatternController = TextEditingController(
      text: widget.initialConfig?.jsonPattern ?? '',
    );

    if (widget.initialConfig != null) {
      _selectedType = widget.initialConfig!.type;
      _qos = widget.initialConfig!.qos;
      _selectedColor = widget.initialConfig!.color;
      _selectedIconCodePoint = widget.initialConfig!.iconCodePoint;
      _mapMarkerIcon = widget.initialConfig!.mapMarkerIcon;
      _isJsonPayload = widget.initialConfig!.isJsonPayload;
      _decimalPlaces = widget.initialConfig!.decimalPlaces;
    } else if (widget.preSelectedType != null) {
      _selectedType = widget.preSelectedType!;
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
    _warningThresholdController.dispose();
    _criticalThresholdController.dispose();
    _optionsController.dispose();
    _jsonPathController.dispose();
    _jsonPatternController.dispose();
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<WidgetType>(
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
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () => _showHelpDialog(context),
                          tooltip: 'How to use this widget',
                        ),
                      ),
                    ],
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
                        bool isOptional =
                            _selectedType == WidgetType.toggle ||
                            _selectedType == WidgetType.button ||
                            _selectedType == WidgetType.slider ||
                            _selectedType == WidgetType.knob;

                        if (!isOptional &&
                            _needsSubscribeTopic() &&
                            (value == null || value.isEmpty)) {
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
                        if (_needsPublishTopic() &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter a publish topic';
                        }
                        return null;
                      },
                    ),
                  if (_needsPublishTopic() || _needsSubscribeTopic()) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Enable JSON Data'),
                            subtitle: const Text(
                              'Parse or send data in JSON format',
                            ),
                            value: _isJsonPayload,
                            onChanged: (val) {
                              setState(() {
                                _isJsonPayload = val;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'JSON Documentation',
                          onPressed: () => _showJsonHelpDialog(context),
                        ),
                      ],
                    ),
                  ],
                  if (_isJsonPayload) ...[
                    if (_needsSubscribeTopic())
                      TextFormField(
                        controller: _jsonPathController,
                        decoration: const InputDecoration(
                          labelText: 'JsonPath for Subscribe',
                          hintText: r'$.store.book[0].title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (_needsSubscribeTopic()) const SizedBox(height: 8),
                    if (_needsPublishTopic())
                      TextFormField(
                        controller: _jsonPatternController,
                        decoration: const InputDecoration(
                          labelText: 'JSON Pattern for Publish',
                          hintText: r'{"data": <value>}',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (_needsPublishTopic()) const SizedBox(height: 8),
                  ],
                  if (_needsOptions())
                    TextFormField(
                      controller: _optionsController,
                      decoration: const InputDecoration(
                        labelText: 'Options / Labels (comma separated)',
                        border: OutlineInputBorder(),
                        hintText: 'Low,Med,High or S1,S2,S3',
                      ),
                      validator: (value) {
                        // Optional or required?
                        return null;
                      },
                    ),
                  if (_needsOptions()) const SizedBox(height: 16),
                  if (_selectedType == WidgetType.toggle &&
                      !_isJsonPayload) ...[
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
                  if (_selectedType == WidgetType.button &&
                      !_isJsonPayload) ...[
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
                  if (_selectedType == WidgetType.statusIndicator &&
                      !_isJsonPayload) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _onPayloadController,
                            decoration: const InputDecoration(
                              labelText: 'Active Payload',
                              border: OutlineInputBorder(),
                              hintText: 'ON, 1, etc',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _offPayloadController,
                            decoration: const InputDecoration(
                              labelText: 'Inactive Payload',
                              border: OutlineInputBorder(),
                              hintText: 'OFF, 0, etc',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedType == WidgetType.gauge ||
                      _selectedType == WidgetType.lineChart ||
                      _selectedType == WidgetType.slider ||
                      _selectedType == WidgetType.barChart ||
                      _selectedType == WidgetType.kpiCard ||
                      _selectedType == WidgetType.liquidTank ||
                      _selectedType == WidgetType.radialGauge ||
                      _selectedType == WidgetType.knob ||
                      _selectedType == WidgetType.battery ||
                      _selectedType == WidgetType.linearGauge ||
                      _selectedType == WidgetType.compass) ...[
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
                    // Decimal Places Selector
                    Row(
                      children: [
                        const Text(
                          'Number Format: ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8), // Reduced spacing
                        Expanded(
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(
                                value: 0,
                                label: Text('123'),
                                tooltip: 'Integer (No decimals)',
                              ),
                              ButtonSegment(
                                value: 1,
                                label: Text('123.4'),
                                tooltip: '1 Decimal Place',
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text('123.45'),
                                tooltip: '2 Decimal Places',
                              ),
                            ],
                            selected: {_decimalPlaces},
                            onSelectionChanged: (Set<int> newSelection) {
                              setState(() {
                                _decimalPlaces = newSelection.first;
                              });
                            },
                            showSelectedIcon: false, // Save space
                            style: ButtonStyle(
                              visualDensity:
                                  VisualDensity.compact, // Reduce height
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedType == WidgetType.gauge ||
                      _selectedType == WidgetType.lineChart) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _warningThresholdController,
                            decoration: const InputDecoration(
                              labelText: 'Warning Threshold',
                              border: OutlineInputBorder(),
                              hintText: 'e.g. 80',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _criticalThresholdController,
                            decoration: const InputDecoration(
                              labelText: 'Critical Threshold',
                              border: OutlineInputBorder(),
                              hintText: 'e.g. 90',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                                    _mapMarkerIcon = isSelected
                                        ? null
                                        : iconNumber;
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
                                      color: isSelected
                                          ? _selectedColor
                                          : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/icon/$iconNumber.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                '$iconNumber',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? _selectedColor
                                                      : Colors.grey,
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
                      DropdownMenuItem(
                        value: 0,
                        child: Text('0 - At most once'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('1 - At least once'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('2 - Exactly once'),
                      ),
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
                        children:
                            [
                              Colors.blue,
                              Colors.green,
                              Colors.orange,
                              Colors.red,
                              Colors.purple,
                              Colors.teal,
                              Colors.pink,
                              Colors.indigo,
                            ].map((color) {
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
                                      color: _selectedColor == color
                                          ? Colors.black
                                          : Colors.transparent,
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
                  if (_selectedType == WidgetType.toggle ||
                      _selectedType == WidgetType.button ||
                      _selectedType == WidgetType.statusIndicator ||
                      _selectedType == WidgetType.kpiCard) ...[
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
        _selectedType == WidgetType.liquidTank ||
        _selectedType == WidgetType.map ||
        _selectedType == WidgetType.slider ||
        _selectedType == WidgetType.statusIndicator ||
        _selectedType == WidgetType.kpiCard ||
        _selectedType == WidgetType.barChart ||
        _selectedType == WidgetType.radialGauge ||
        _selectedType == WidgetType.battery ||
        _selectedType == WidgetType.terminal ||
        _selectedType == WidgetType.knob ||
        _selectedType == WidgetType.linearGauge ||
        _selectedType == WidgetType.compass ||
        _selectedType == WidgetType.text ||
        _selectedType == WidgetType.textInput ||
        _selectedType == WidgetType.iconMatrix;
  }

  bool _needsPublishTopic() {
    return _selectedType == WidgetType.toggle ||
        _selectedType == WidgetType.button ||
        _selectedType == WidgetType.slider ||
        _selectedType == WidgetType.knob ||
        _selectedType == WidgetType.segmentedSwitch ||
        _selectedType == WidgetType.joystick ||
        _selectedType == WidgetType.textInput ||
        _selectedType == WidgetType.keypad;
  }

  bool _needsOptions() {
    return _selectedType == WidgetType.segmentedSwitch ||
        _selectedType == WidgetType.iconMatrix;
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
      case WidgetType.statusIndicator:
        return 'Status Indicator';
      case WidgetType.kpiCard:
        return 'KPI Card';
      case WidgetType.barChart:
        return 'Bar Chart';
      case WidgetType.liquidTank:
        return 'Liquid Tank';
      case WidgetType.radialGauge:
        return 'Radial Gauge';
      case WidgetType.knob:
        return 'Control Knob';
      case WidgetType.battery:
        return 'Battery Level';
      case WidgetType.terminal:
        return 'Terminal Log';
      case WidgetType.segmentedSwitch:
        return 'Segmented Switch';
      case WidgetType.linearGauge:
        return 'Linear Gauge';
      case WidgetType.joystick:
        return 'Virtual Joystick';
      case WidgetType.compass:
        return 'Compass';
      case WidgetType.keypad:
        return 'Keypad';
      case WidgetType.textInput:
        return 'Text Input';
      case WidgetType.iconMatrix:
        return 'Icon Matrix';
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
                IconHelper.getIcon(_selectedIconCodePoint) ?? Icons.widgets,
                color: _selectedColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text.isEmpty
                        ? 'Preview title'
                        : _titleController.text,
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
                style: TextStyle(
                  color: _selectedColor,
                  fontWeight: FontWeight.bold,
                ),
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
          color: isSelected
              ? _selectedColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(iconData, color: isSelected ? _selectedColor : Colors.grey),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getWidgetTypeName(_selectedType)} Guide'),
        content: SingleChildScrollView(
          child: Text(_getWidgetHelpText(_selectedType)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getWidgetHelpText(WidgetType type) {
    switch (type) {
      case WidgetType.toggle:
        return 'Controls ON/OFF status (boolean).\n\nRequires:\n- Publish Topic: to send commands.\n- Subscribe Topic (Optional): to listen for status updates.\n- On/Off Payload: "ON"/"OFF" or "1"/"0".';
      case WidgetType.button:
        return 'Sends a momentary command when pressed.\n\nRequires:\n- Publish Topic: Command destination.\n- Payload: Command to send.';
      case WidgetType.slider:
        return 'Controls a numeric value within a range.\n\nRequires:\n- Publish Topic: to set value.\n- Min/Max Value.\n- Optional: Subscribe Topic to sync status.';
      case WidgetType.gauge:
      case WidgetType.radialGauge:
        return 'Visualizes numeric data on a circular meter.\n\nRequires:\n- Subscribe Topic: Source of data.\n- Min/Max Value.\n- Thresholds (Warning/Critical): Optional for color indication.';
      case WidgetType.linearGauge:
        return 'Visualizes numeric data on a horizontal bar.\n\nRequires:\n- Subscribe Topic.\n- Min/Max Value.\n- Thresholds.';
      case WidgetType.barChart:
      case WidgetType.lineChart:
        return 'Displays data history/trends.\n\nRequires:\n- Subscribe Topic.\n- Min/Max Value (Y-axis range).';
      case WidgetType.text:
      case WidgetType.kpiCard:
        return 'Displays raw text or key numeric metris.\n\nRequires:\n- Subscribe Topic.';
      case WidgetType.statusIndicator:
        return 'Simple colored indicator for ON/OFF status.\n\nRequires:\n- Subscribe Topic.';
      case WidgetType.map:
        return 'Tracks device location.\n\nRequires:\n- Subscribe Topic: Payload must be "lat,long" csv or JSON.\n- Map Icon: Marker style.';
      case WidgetType.liquidTank:
        return 'Visualizes liquid level percentage.\n\nRequires:\n- Subscribe Topic.\n- Min/Max Value (Capacity).';
      case WidgetType.knob:
        return 'Rotary control for numeric values.\n\nRequires:\n- Publish Topic.\n- Min/Max Value.';
      case WidgetType.battery:
        return 'Displays battery percentage with color coding.\n\nRequires:\n- Subscribe Topic: 0-100 value.';
      case WidgetType.terminal:
        return 'Logs raw MQTT messages with timestamps.\n\nRequires:\n- Subscribe Topic.';
      case WidgetType.segmentedSwitch:
        return 'Multi-state switch (e.g., Low/Med/High).\n\nRequires:\n- Publish Topic.\n- Options: Comma-separated labels (e.g., "Low,Med,High").';
      case WidgetType.joystick:
        return 'Virtual Analog Joystick Control.\n\nRequires:\n- Publish Topic: Sends JSON {"x":val, "y":val}.';
      case WidgetType.compass:
        return 'Displays heading direction (0-360 degrees).\n\nRequires:\n- Subscribe Topic.';
      case WidgetType.keypad:
        return 'Numeric Keypad for PIN entry.\n\nRequires:\n- Publish Topic.';
      case WidgetType.textInput:
        return 'Sends text strings to a topic.\n\nRequires:\n- Publish Topic.\n- Optional: Subscribe Topic to see current value.';
      case WidgetType.iconMatrix:
        return 'Grid of status indicators.\n\nRequires:\n- Subscribe Topic: Integer bitmask.\n- Options: Comma-separated labels for each indicator bit.';
      default:
        return 'No help available for this widget.';
    }
  }

  void _showJsonHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Data Documentation'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subscribe JSON Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You can parse received messages using simple JsonPath. The supported JsonPath are listed below.\n\n'
                '\$	: The root object/element\n'
                '@	: The current object/element\n'
                '. :	Child member operator\n'
                '.. :	Recursive descendant operator\n'
                '* :	Wildcard matching all objects/elements regardless their names\n'
                '[ ]	 : Subscript operator\n'
                '[ , ] :	Union operator for alternate names or array indices as a set\n'
                '?( )	: Applies a filter (script) expression via static evaluation\n'
                '( )	 : Script expression via static evaluation\n\n'
                'Note: Only a single quote is supported inside JsonPath expression. Script expressions inside of JSONPath locations are not recursively evaluated by JsonPath. Only the global \$ and local @ symbols are expanded by a simple regular expression. This application does not validate JsonPath you provided. In case JsonPath is invalid or it does not match with any data it simply gets ignored. For debugging please use the Text Input and Text Log Panel.',
              ),
              Divider(height: 24),
              Text(
                'Publish JSON Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You can wrap publish data into a JSON format. For example, you have configured {"kitchen": {"fan": "<slider-payload>"}} as JSON pattern. Now if you set slider value to 10, then <slider-payload> will be replaced by 10 and finally {"kitchen": {"fan": "10"}} will be published.\n\n'
                'You can use multiple replaceable variable like <timestamp>, <client-id> etc. depending on the context. To know all available variables, press the inline help button while configuring the panel.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
        subscribeTopic: _subscribeTopicController.text.isEmpty
            ? null
            : _subscribeTopicController.text,
        publishTopic: _publishTopicController.text.isEmpty
            ? null
            : _publishTopicController.text,
        onPayload: _onPayloadController.text,
        offPayload: _offPayloadController.text,
        qos: _qos,
        colorValue: _selectedColor.value,
        iconCodePoint: _selectedIconCodePoint,
        minValue: minValue,
        maxValue: maxValue,
        unit: _unitController.text.isEmpty ? null : _unitController.text,
        // Map new fields
        options: _optionsController.text.isNotEmpty
            ? _optionsController.text.split(',').map((e) => e.trim()).toList()
            : null,
        warningThreshold: double.tryParse(_warningThresholdController.text),
        criticalThreshold: double.tryParse(_criticalThresholdController.text),
        isMovingMode: false, // Default: static mode, can be toggled from panel
        idleTimeoutSeconds: 10, // Default timeout
        mapMarkerIcon: _mapMarkerIcon,
        isJsonPayload: _isJsonPayload,
        jsonPath: _isJsonPayload ? _jsonPathController.text : null,
        jsonPattern: _isJsonPayload ? _jsonPatternController.text : null,
        decimalPlaces: _decimalPlaces,
        x: widget.initialConfig?.x ?? 0,
        y: widget.initialConfig?.y ?? 0,
        width: widget.initialConfig?.width ?? 1,
        height: widget.initialConfig?.height ?? 1,
      );

      Navigator.pop(context, config);
    }
  }
}
