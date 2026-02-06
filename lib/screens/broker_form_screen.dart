import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/broker_config.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../services/secure_credential_storage.dart';

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
  bool _showPassword = false;
  
  // SSL/TLS Configuration
  SslConfig _sslConfig = SslConfig();
  bool _showAdvancedSsl = false;
  
  // Certificate upload state
  String? _certificateFileName;
  String? _privateKeyFileName;
  bool _isUploading = false;
  
  final SecureCredentialStorage _secureStorage = SecureCredentialStorage();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.broker?.name ?? '');
    _hostController = TextEditingController(text: widget.broker?.host ?? '');
    _portController = TextEditingController(text: widget.broker?.port.toString() ?? '1883');
    _usernameController = TextEditingController(text: widget.broker?.username ?? '');
    _passwordController = TextEditingController();
    _clientIdController = TextEditingController(text: widget.broker?.clientId ?? '');
    _useSsl = widget.broker?.useSsl ?? false;
    
    // Load SSL config if exists
    if (widget.broker?.sslConfig != null) {
      _sslConfig = widget.broker!.sslConfig!;
    }
    
    // Load existing certificate info if editing
    if (widget.broker != null) {
      _loadCertificateInfo();
    }
  }

  Future<void> _loadCertificateInfo() async {
    if (widget.broker == null) return;
    
    final info = await _secureStorage.getCertificateInfo(widget.broker!.id);
    if (mounted) {
      setState(() {
        _certificateFileName = info['hasCertificate'] ? 'certificate.pem' : null;
        _privateKeyFileName = info['hasPrivateKey'] ? 'private.key' : null;
      });
    }
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
          IconButton(
            tooltip: 'Test Connection',
            icon: const Icon(Icons.wifi),
            onPressed: _isTesting ? null : _testConnection,
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
              // Basic Info Section
              _buildSectionHeader('Connection Details'),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Broker Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
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
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: SwitchListTile(
                      title: const Text('SSL/TLS'),
                      value: _useSsl,
                      onChanged: (value) {
                        setState(() {
                          _useSsl = value;
                          if (value) {
                            _sslConfig.enabled = true;
                            if (_portController.text == '1883') {
                              _portController.text = '8883';
                            }
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Authentication Section
              _buildSectionHeader('Authentication (Optional)'),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                obscureText: !_showPassword,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Client ID (Auto-generated if empty)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              
              // SSL/TLS Certificate Section
              if (_useSsl) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('SSL/TLS Certificates'),
                
                _buildCertificateTypeSelector(),
                
                if (_sslConfig.certificateType != CertificateType.none) ...[
                  const SizedBox(height: 16),
                  _buildCertificateUploadSection(),
                ],
                
                // Advanced SSL Settings
                _buildAdvancedSslSettings(),
              ],
              
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _saveBroker,
                icon: const Icon(Icons.save),
                label: Text(widget.broker == null ? 'Save Broker' : 'Update Broker'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Certificate Type:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCertificateTypeOption(
                  CertificateType.none,
                  'None',
                  Icons.no_encryption,
                  'No certificate authentication',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCertificateTypeOption(
                  CertificateType.caCertificate,
                  'CA Signed',
                  Icons.verified,
                  'Server has CA-signed certificate',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCertificateTypeOption(
                  CertificateType.clientCertificate,
                  'Client Cert',
                  Icons.badge,
                  'Mutual TLS authentication',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCertificateTypeOption(
                  CertificateType.selfSigned,
                  'Self-Signed',
                  Icons.warning,
                  'Accept self-signed certificates',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTypeOption(
    CertificateType type,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _sslConfig.certificateType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sslConfig.certificateType = type;
          if (type == CertificateType.none) {
            _sslConfig.enabled = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateUploadSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sslConfig.certificateType == CertificateType.clientCertificate) ...[
            // Upload CA Certificate
            _buildFilePicker(
              'CA Certificate (.pem, .crt, .ca-bundle)',
              _certificateFileName ?? 'No certificate selected',
              Icons.verified,
              _pickCertificate,
            ),
            const SizedBox(height: 12),
            
            // Upload Client Certificate
            _buildFilePicker(
              'Client Certificate (.pem, .crt)',
              _certificateFileName ?? 'No certificate selected',
              Icons.badge,
              _pickClientCertificate,
            ),
            const SizedBox(height: 12),
            
            // Upload Private Key
            _buildFilePicker(
              'Private Key (.pem, .key)',
              _privateKeyFileName ?? 'No key selected',
              Icons.vpn_key,
              _pickPrivateKey,
            ),
          ] else if (_sslConfig.certificateType == CertificateType.caCertificate) ...[
            // Upload CA Certificate only
            _buildFilePicker(
              'CA Certificate (.pem, .crt, .ca-bundle)',
              _certificateFileName ?? 'No certificate selected',
              Icons.verified,
              _pickCertificate,
            ),
          ] else if (_sslConfig.certificateType == CertificateType.selfSigned) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Self-Signed Certificate',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber),
                        ),
                        Text(
                          'Will accept any certificate (less secure)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_sslConfig.certificateVerified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Certificate verified successfully'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePicker(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: value.startsWith('No') ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isUploading ? Icons.hourglass_top : Icons.upload_file,
              color: _isUploading ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSslSettings() {
    return ExpansionTile(
      title: const Text('Advanced SSL Settings'),
      initiallyExpanded: _showAdvancedSsl,
      onExpansionChanged: (value) => setState(() => _showAdvancedSsl = value),
      children: [
        SwitchListTile(
          title: const Text('Accept Self-Signed Certificates'),
          subtitle: const Text('Allow certificates that are not signed by a CA'),
          value: _sslConfig.acceptSelfSigned,
          onChanged: (value) => setState(() => _sslConfig.acceptSelfSigned = value),
        ),
        SwitchListTile(
          title: const Text('Verify Server Certificate'),
          subtitle: const Text('Verify the server\'s certificate chain'),
          value: _sslConfig.verifyCertificate,
          onChanged: (value) => setState(() => _sslConfig.verifyCertificate = value),
        ),
        const ListTile(
          title: Text('Allowed TLS Versions'),
          subtitle: Text('TLS 1.2, TLS 1.3'),
        ),
      ],
    );
  }

  Future<void> _pickCertificate() async {
    setState(() => _isUploading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'crt', 'ca-bundle', 'cer'],
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileBytes = await File(filePath).readAsBytes();
        final brokerId = widget.broker?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        await _secureStorage.saveCertificate(
          brokerId: brokerId,
          certificateBytes: fileBytes,
        );
        
        if (mounted) {
          setState(() {
            _certificateFileName = result.files.single.name;
            _sslConfig.certificateId = brokerId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading certificate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickClientCertificate() async {
    setState(() => _isUploading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'crt', 'cert'],
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileBytes = await File(filePath).readAsBytes();
        final brokerId = widget.broker?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        await _secureStorage.saveCertificate(
          brokerId: brokerId,
          certificateBytes: fileBytes,
        );
        
        if (mounted) {
          setState(() {
            _certificateFileName = result.files.single.name;
            _sslConfig.certificateId = brokerId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading certificate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickPrivateKey() async {
    setState(() => _isUploading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'key'],
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileBytes = await File(filePath).readAsBytes();
        final brokerId = widget.broker?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        await _secureStorage.saveCertificate(
          brokerId: brokerId,
          certificateBytes: Uint8List(0),
          privateKeyBytes: fileBytes,
        );
        
        if (mounted) {
          setState(() {
            _privateKeyFileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading private key: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final testConfig = BrokerConfig(
        name: _nameController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text.isEmpty ? null : _usernameController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        useSsl: _useSsl,
        clientId: _clientIdController.text.isEmpty ? null : _clientIdController.text,
        sslConfig: _sslConfig,
      );

      final service = ref.read(mqttServiceProvider);
      final success = await service.connect(testConfig, autoReconnect: false);

      if (mounted) {
        setState(() => _isTesting = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Connection successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          _showConnectionErrorDialog(service.lastError ?? 'Unknown error');
        }
      }

      if (success) {
        await service.disconnect();
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showConnectionErrorDialog(String error) {
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
                'Error: $error',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Troubleshooting Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('1. Check if the broker address is correct'),
              const Text('2. Verify the port number (1883 for non-SSL, 8883 for SSL)'),
              const Text('3. Check your internet connection'),
              const Text('4. Try a public broker first'),
              const Text('5. For SSL, ensure certificates are valid'),
              const SizedBox(height: 16),
              const Text('Public brokers:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• broker.hivemq.com:1883'),
              const Text('• test.mosquitto.org:1883'),
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
                'HiveMQ SSL',
                'broker.hivemq.com',
                8883,
                'SSL/TLS connection',
                useSsl: true,
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

  Widget _buildBrokerOption(
    String name,
    String host,
    int port,
    String description, {
    bool useSsl = false,
  }) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('$host:$port\n$description'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useSsl)
              const Icon(Icons.lock, size: 16, color: Colors.green),
            const Icon(Icons.arrow_forward),
          ],
        ),
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

  Future<void> _saveBroker() async {
    if (!_formKey.currentState!.validate()) return;

    final brokerId = widget.broker?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Simpan credentials ke secure storage
    if (_usernameController.text.isNotEmpty || _passwordController.text.isNotEmpty) {
      await _secureStorage.saveBrokerCredentials(
        brokerId: brokerId,
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }

    final broker = BrokerConfig(
      id: brokerId,
      name: _nameController.text,
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text.isEmpty ? null : _usernameController.text,
      useSsl: _useSsl,
      sslConfig: _sslConfig.enabled ? _sslConfig : null,
      hasSecureCredentials: true,
      clientId: _clientIdController.text.isEmpty ? null : _clientIdController.text,
    );

    if (widget.broker == null) {
      ref.read(brokerConfigsProvider.notifier).addBroker(broker);
    } else {
      ref.read(brokerConfigsProvider.notifier).updateBroker(broker);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
