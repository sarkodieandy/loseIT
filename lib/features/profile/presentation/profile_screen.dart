import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import 'badges_grid_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final badgesAsync = ref.watch(earnedBadgesProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const SectionCard(child: Text('No profile data.'));
              }
              return SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.displayHabitName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Start: ${Formatters.date.format(profile.soberStartDate)}'),
                    if (profile.motivationText != null) ...[
                      const SizedBox(height: 8),
                      Text('Motivation: ${profile.motivationText}'),
                    ],
                    if (profile.motivationPhotoUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          profile.motivationPhotoUrl!,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const SectionCard(child: Text('Loading profile…')),
            error: (error, _) => SectionCard(child: Text('Error: $error')),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.workspace_premium),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isPremium ? 'Premium active' : 'Free plan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPremium
                            ? 'Thanks for supporting Be Sober.'
                            : 'Unlock multi-habit, insights, voice journal, and more.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.push('/paywall'),
                  child: Text(isPremium ? 'Manage' : 'Go Premium'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          badgesAsync.when(
            data: (badges) {
              if (badges.isEmpty) {
                return SectionCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: <Widget>[
                          const Text('🎯', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No badges earned yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return BadgesGrid(badges: badges);
            },
            loading: () => const SectionCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => SectionCard(
              child: Text('Badges failed: $error'),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Appearance',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  isExpanded: true,
                  items: const <DropdownMenuItem<ThemeMode>>[
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Account', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/habits'),
                  child: const Text('Manage habits'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/recovery-plan'),
                  child: const Text('Recovery plan'),
                ),
                const SizedBox(height: 8),
                PremiumGate(
                  lockedTitle: 'Support network',
                  lockedDescription: 'Premium required.',
                  child: OutlinedButton(
                    onPressed: () => context.push('/support'),
                    child: const Text('Support network'),
                  ),
                ),
                const SizedBox(height: 8),
                PremiumGate(
                  lockedTitle: 'Custom milestones',
                  lockedDescription: 'Premium required.',
                  child: OutlinedButton(
                    onPressed: () => context.push('/milestones'),
                    child: const Text('Custom milestones'),
                  ),
                ),
                const SizedBox(height: 8),
                PremiumGate(
                  lockedTitle: 'Export data',
                  lockedDescription: 'Premium required.',
                  child: OutlinedButton(
                    onPressed: () => _exportData(context, ref),
                    child: const Text('Export data'),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .setOnboardingComplete(false);
                  },
                  child: const Text('Log out'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final info =
                        await RevenueCatService.instance.restorePurchases();
                    if (!context.mounted) return;
                    final restored = info != null &&
                        RevenueCatService.instance.isPremiumFrom(info);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(restored
                            ? 'Purchases restored.'
                            : 'No active subscription found.'),
                      ),
                    );
                  },
                  child: const Text('Restore purchases'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final entries = ref.read(journalControllerProvider).value ?? const [];
  final buffer = StringBuffer();
  buffer.writeln('date,content,mood');
  for (final entry in entries) {
    final content = entry.content.replaceAll(',', ' ');
    buffer.writeln(
        '${entry.entryDate.toIso8601String()},$content,${entry.mood ?? ''}');
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/be_sober_export.csv');
  await file.writeAsString(buffer.toString());
  if (context.mounted) {
    await Share.shareXFiles([XFile(file.path)], text: 'Be Sober export');
  }
}
