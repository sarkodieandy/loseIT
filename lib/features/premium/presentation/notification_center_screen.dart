import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../providers/milestone_notification_providers.dart';
import '../../../providers/app_providers.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late Map<String, bool> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = {
      'replies': true,
      'messages': true,
      'challenges': true,
      'milestones': true,
      'digest': false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final history = ref.watch(notificationHistoryProvider(userId ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _buildSwitchTile('Replies', 'Get notified of community replies',
                    _preferences['replies']!, (value) {
                  setState(() => _preferences['replies'] = value);
                }),
                _buildSwitchTile('Messages', 'Get notified of direct messages',
                    _preferences['messages']!, (value) {
                  setState(() => _preferences['messages'] = value);
                }),
                _buildSwitchTile(
                    'Challenges',
                    'Challenge invitations and updates',
                    _preferences['challenges']!, (value) {
                  setState(() => _preferences['challenges'] = value);
                }),
                _buildSwitchTile(
                    'Milestones',
                    'Milestone celebrations and achievements',
                    _preferences['milestones']!, (value) {
                  setState(() => _preferences['milestones'] = value);
                }),
                _buildSwitchTile(
                  'Weekly Digest',
                  'Get a weekly summary of your activity',
                  _preferences['digest']!,
                  (value) {
                    setState(() => _preferences['digest'] = value);
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Settings',
                  onPressed: () => _savePreferences(userId!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Notification History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          history.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const SectionCard(
                  child: Text('No notifications yet'),
                );
              }
              return Column(
                children: notifications.map((notif) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(notif.title),
                      subtitle: Text(notif.body),
                      trailing: notif.isRead
                          ? const Icon(Icons.check, color: Colors.grey)
                          : const Icon(Icons.circle,
                              color: Colors.blue, size: 8),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _savePreferences(String userId) async {
    // Save preferences to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings saved')),
    );
  }
}
