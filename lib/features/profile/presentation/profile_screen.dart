import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final isPremium = ref.watch(premiumControllerProvider);
    final badgesAsync = ref.watch(userBadgesProvider);

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
                    Text('Start: ${Formatters.date.format(profile.soberStartDate)}'),
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
            child: badgesAsync.when(
              data: (badges) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Earned: ${badges.length}'),
                ],
              ),
              loading: () => const Text('Loading badges…'),
              error: (error, _) => Text('Badges failed: $error'),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
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
                      ref.read(settingsControllerProvider.notifier).setThemeMode(value);
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
                  onPressed: () => context.push('/support'),
                  child: const Text('Support network'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/milestones'),
                  child: const Text('Custom milestones'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _exportData(context, ref),
                  child: const Text('Export data'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    await ref.read(settingsControllerProvider.notifier).setOnboardingComplete(false);
                  },
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Premium', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  isPremium ? 'You are Premium.' : 'Unlock advanced features.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/premium'),
                  child: Text(isPremium ? 'Manage subscription' : 'Go Premium'),
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
    buffer.writeln('${entry.entryDate.toIso8601String()},$content,${entry.mood ?? ''}');
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/be_sober_export.csv');
  await file.writeAsString(buffer.toString());
  if (context.mounted) {
    await Share.shareXFiles([XFile(file.path)], text: 'Be Sober export');
  }
}
