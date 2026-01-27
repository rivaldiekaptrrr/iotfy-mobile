import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/broker_config.dart';
import '../providers/mqtt_providers.dart';
import '../providers/storage_providers.dart';
import '../services/mqtt_service.dart';
import 'broker_form_screen.dart';
import 'dashboard_list_screen.dart';

class BrokerListScreen extends ConsumerWidget {
  const BrokerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brokers = ref.watch(brokerConfigsProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final theme = Theme.of(context);

    // Filter active brokers/dashboards for "Recent" or "Active" view
    // For now, listing all brokers in a premium way.

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            expandedHeight: 180,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 24),
              title: Text(
                'Control Center',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.05),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 100,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text('Connections', style: theme.textTheme.titleLarge),
            ),
          ),

          if (brokers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, _addBroker),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final broker = brokers[index];
                  final mqttService = ref.watch(mqttServiceProvider);
                  final currentConfig = mqttService.currentConfig;
                  final isCurrentBroker = currentConfig?.id == broker.id;
                  final status =
                      connectionStatus.value ?? ConnectionStatus.disconnected;

                  final isConnected =
                      isCurrentBroker && status == ConnectionStatus.connected;
                  final isConnecting =
                      isCurrentBroker && status == ConnectionStatus.connecting;

                  return _BrokerPremiumCard(
                    broker: broker,
                    isConnected: isConnected,
                    isConnecting: isConnecting,
                    onTap: () => _connectAndExplore(context, ref, broker),
                    onEdit: () => _editBroker(context, broker),
                    onDelete: () => ref
                        .read(brokerConfigsProvider.notifier)
                        .deleteBroker(broker.id),
                    onConnectToggle: () async {
                      if (isConnected || isConnecting) {
                        await mqttService.disconnect();
                      } else {
                        await mqttService.connect(broker);
                      }
                    },
                  );
                }, childCount: brokers.length),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ), // Bottom padding
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBroker(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Connection'),
        elevation: 4,
        highlightElevation: 8,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Function(BuildContext) onAdd) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hub_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Start Your Journey',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect to an MQTT broker to verify your IoT devices.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton.tonalIcon(
          onPressed: () => onAdd(context),
          icon: const Icon(Icons.bolt),
          label: const Text('Connect Broker'),
        ),
      ],
    );
  }

  void _addBroker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BrokerFormScreen()),
    );
  }

  void _editBroker(BuildContext context, BrokerConfig broker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BrokerFormScreen(broker: broker)),
    );
  }

  Future<void> _connectAndExplore(
    BuildContext context,
    WidgetRef ref,
    BrokerConfig broker,
  ) async {
    // Navigate to Dashboard List for this broker
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardListScreen(brokerId: broker.id),
      ),
    );
  }
}

class _BrokerPremiumCard extends StatelessWidget {
  final BrokerConfig broker;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConnectToggle;

  const _BrokerPremiumCard({
    required this.broker,
    required this.isConnected,
    this.isConnecting = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onConnectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.dns_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          broker.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${broker.host}:${broker.port}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Connection Action Button
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onConnectToggle,
                      style: FilledButton.styleFrom(
                        backgroundColor: isConnected
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.primaryContainer,
                        foregroundColor: isConnected
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      child: isConnecting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : Text(isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Dashboard Action
                  Tooltip(
                    message: isConnected
                        ? 'View dashboards'
                        : 'Connect to broker first to access dashboards',
                    child: OutlinedButton.icon(
                      onPressed: isConnected ? onTap : null,
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: const Text('Visit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // More Actions
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: onEdit,
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Config'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: onDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: const Text(
          '...',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Theme.of(context).disabledColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? Colors.green.withOpacity(0.2)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isConnected ? Colors.green : Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
