import 'package:flutter/material.dart';
import '../models/panel_widget_config.dart';

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
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedType == WidgetType.gauge || _selectedType == WidgetType.lineChart) ...[
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
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 16),
                      ...[ Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
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
                      }),
                    ],
                  ),
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
        _selectedType == WidgetType.lineChart;
  }

  bool _needsPublishTopic() {
    return _selectedType == WidgetType.toggle || _selectedType == WidgetType.button;
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
    }
  }

  void _saveWidget() {
    if (_formKey.currentState!.validate()) {
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
        minValue: double.tryParse(_minValueController.text) ?? 0,
        maxValue: double.tryParse(_maxValueController.text) ?? 100,
        unit: _unitController.text.isEmpty ? null : _unitController.text,
      );

      Navigator.pop(context, config);
    }
  }
}