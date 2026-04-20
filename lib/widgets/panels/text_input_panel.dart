import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/panel_widget_config.dart';
import '../../providers/mqtt_providers.dart';

class TextInputPanel extends ConsumerStatefulWidget {
  final PanelWidgetConfig config;

  const TextInputPanel({super.key, required this.config});

  @override
  ConsumerState<TextInputPanel> createState() => _TextInputPanelState();
}

class _TextInputPanelState extends ConsumerState<TextInputPanel> {
  late TextEditingController _controller;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publishMessage() async {
    final text = _controller.text;
    if (text.isEmpty || widget.config.publishTopic == null) return;

    setState(() => _isPublishing = true);

    try {
      final mqttService = ref.read(mqttServiceProvider);
      mqttService.publish(
        widget.config.publishTopic!,
        text,
        qos: widget.config.qos,
        retain: false, // Could be added to config if needed
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to ${widget.config.publishTopic}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.config.icon != null) ...[
                Icon(widget.config.icon, color: widget.config.color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.config.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter text...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true, // Make it compact
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  onSubmitted: (_) => _publishMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isPublishing ? null : _publishMessage,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.config.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: _isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: const Text('Send'),
              ),
            ],
          ),
          const Spacer(),
          if (widget.config.publishTopic != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Topic: ${widget.config.publishTopic}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
