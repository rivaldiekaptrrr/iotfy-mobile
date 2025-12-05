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
        actions: [
          if (widget.broker == null)
            TextButton.icon(
              onPressed: _showPublicBrokers,
              icon: const Icon(Icons.cloud),
              label: const Text('Public Brokers'),
            ),
        ],
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

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Connection successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Failed'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error: ${service.lastError}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Troubleshooting Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('1. Check if the broker address is correct'),
                  const Text('2. Verify the port number (1883 for non-SSL, 8883 for SSL)'),
                  const Text('3. Check your internet connection'),
                  const Text('4. Try a different public broker'),
                  const Text('5. Disable firewall temporarily to test'),
                  const Text('6. Some networks block MQTT ports'),
                  const SizedBox(height: 16),
                  const Text('Recommended public brokers:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('• broker.hivemq.com:1883'),
                  const Text('• test.mosquitto.org:1883'),
                  const Text('• broker.emqx.io:1883'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (success) {
        await service.disconnect();
      }
    }
  }

  void _showPublicBrokers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Public MQTT Brokers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildBrokerOption(
                'Eclipse Mosquitto',
                'test.mosquitto.org',
                1883,
                'Free public broker by Eclipse',
              ),
              _buildBrokerOption(
                'HiveMQ Public',
                'broker.hivemq.com',
                1883,
                'Free public broker by HiveMQ',
              ),
              _buildBrokerOption(
                'EMQX Public',
                'broker.emqx.io',
                1883,
                'Free public broker by EMQX',
              ),
              _buildBrokerOption(
                'Mosquitto SSL',
                'test.mosquitto.org',
                8883,
                'SSL/TLS connection',
                useSsl: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerOption(String name, String host, int port, String description, {bool useSsl = false}) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('$host:$port\n$description'),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          setState(() {
            _nameController.text = name;
            _hostController.text = host;
            _portController.text = port.toString();
            _useSsl = useSsl;
          });
          Navigator.pop(context);
        },
      ),
    );
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