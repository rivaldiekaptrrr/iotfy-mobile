import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/broker_config.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';

class BrokerFormScreen extends ConsumerStatefulWidget {
  final BrokerConfig? broker;

  const BrokerFormScreen({super.key, this.broker});

  @override
  ConsumerState<BrokerFormScreen> createState() => _BrokerFormScreenState();
}

class _BrokerFormScreenState extends ConsumerState<BrokerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _clientIdController;
  bool _useSsl = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.broker?.name ?? '');
    _hostController = TextEditingController(text: widget.broker?.host ?? '');
    _portController = TextEditingController(text: widget.broker?.port.toString() ?? '1883');
    _usernameController = TextEditingController(text: widget.broker?.username ?? '');
    _passwordController = TextEditingController(text: widget.broker?.password ?? '');
    _clientIdController = TextEditingController(text: widget.broker?.clientId ?? '');
    _useSsl = widget.broker?.useSsl ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.broker == null ? 'Add Broker' : 'Edit Broker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Broker Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host',
                  border: OutlineInputBorder(),
                  hintText: 'broker.hivemq.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid port number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use SSL/TLS'),
                value: _useSsl,
                onChanged: (value) {
                  setState(() {
                    _useSsl = value;
                    if (value) {
                      _portController.text = '8883';
                    } else {
                      _portController.text = '1883';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (optional)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Client ID (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Auto-generated if empty',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isTesting ? null : _testConnection,
                child: _isTesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveBroker,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
    });

    final testConfig = BrokerConfig(
      name: _nameController.text,
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text.isEmpty ? null : _usernameController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      useSsl: _useSsl,
      clientId: _clientIdController.text.isEmpty ? null : _clientIdController.text,
    );

    final service = ref.read(mqttServiceProvider);
    final success = await service.connect(testConfig, autoReconnect: false);

    if (mounted) {
      setState(() {
        _isTesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connection successful!' : 'Connection failed: ${service.lastError}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        await service.disconnect();
      }
    }
  }

  void _saveBroker() {
    if (!_formKey.currentState!.validate()) return;

    final broker = BrokerConfig(
      id: widget.broker?.id,
      name: _nameController.text,
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text.isEmpty ? null : _usernameController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      useSsl: _useSsl,
      clientId: _clientIdController.text.isEmpty ? null : _clientIdController.text,
    );

    if (widget.broker == null) {
      ref.read(brokerConfigsProvider.notifier).addBroker(broker);
    } else {
      ref.read(brokerConfigsProvider.notifier).updateBroker(broker);
    }

    Navigator.pop(context);
  }
}