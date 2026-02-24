import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/repository_providers.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(supportConnectionsProvider);
    final isPremium = ref.watch(premiumControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Support Network')),
      body: PremiumGate(
        lockedTitle: 'Support Network',
        lockedDescription: 'Invite up to 3 trusted contacts to support you.',
        child: connectionsAsync.when(
          data: (connections) {
            if (connections.isEmpty) {
              return const Center(child: Text('No contacts yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) {
                final connection = connections[index];
                return SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(connection.contactName ?? 'Support contact'),
                    subtitle:
                        Text(connection.relationship ?? 'Trusted contact'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/support/${connection.id}'),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: connections.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed: $error')),
        ),
      ),
      floatingActionButton: isPremium.hasAccess
          ? FloatingActionButton(
              heroTag: 'support_add',
              onPressed: () => _showAddDialog(context, ref),
              child: const Icon(Icons.person_add_alt_1),
            )
          : null,
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await ref.read(supportRepositoryProvider).createConnection(
                    contactName: name,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    relationship: relationController.text.trim().isEmpty
                        ? null
                        : relationController.text.trim(),
                  );
              ref.invalidate(supportConnectionsProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}
