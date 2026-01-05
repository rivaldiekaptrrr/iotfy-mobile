import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';
import '../../services/mqtt_service.dart';

class KeypadPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const KeypadPanel({super.key, required this.config});

  @override
  ConsumerState<KeypadPanel> createState() => _KeypadPanelState();
}

class _KeypadPanelState extends ConsumerState<KeypadPanel> {
  String _input = "";

  void _onKeyPress(String key) {
    if (key == 'C') {
      setState(() {
        _input = "";
      });
    } else if (key == 'OK') {
      if (widget.config.publishTopic != null && _input.isNotEmpty) {
        String payload;
        if (widget.config.isJsonPayload && widget.config.jsonPattern != null) {
          String result = widget.config.jsonPattern!;
          result = result.replaceAll('<value>', _input);
          result = result.replaceAll('<keypad-payload>', _input);
          result = result.replaceAll('<timestamp>', DateTime.now().millisecondsSinceEpoch.toString());
          result = result.replaceAll('<iso-timestamp>', DateTime.now().toIso8601String());
          payload = result;
        } else {
          payload = _input;
        }

        ref.read(mqttServiceProvider).publish(
          widget.config.publishTopic!,
          payload,
          retain: false
        );
        setState(() {
          _input = "";
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent!'), duration: Duration(milliseconds: 500)));
        });
      }
    } else {
      if (_input.length < 8) {
        setState(() {
          _input += key;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      'C', '0', 'OK'
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
               Expanded(child: Text(widget.config.title, style: theme.textTheme.titleSmall)),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.surfaceContainerHighest,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   _input.isEmpty ? '---' : _input.replaceAll(RegExp(r'.'), '*'), // Masked? Or visible? Let's make visible for now or maybe configurable. User said "PIN", usually masked.
                   style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                 ),
               )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    Color bgColor = theme.cardColor;
                    Color fgColor = theme.colorScheme.onSurface;
                    
                    if (key == 'OK') {
                      bgColor = Colors.green.withOpacity(0.2);
                      fgColor = Colors.green;
                    } else if (key == 'C') {
                      bgColor = Colors.red.withOpacity(0.2);
                      fgColor = Colors.red;
                    }

                    return Material(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: () => _onKeyPress(key),
                        borderRadius: BorderRadius.circular(4),
                        child: Center(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: fgColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
