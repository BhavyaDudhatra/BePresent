import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';
import 'pin_screens.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isSchool = session.isAdmin || session.isTeacher;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                session.isAdmin
                    ? Icons.admin_panel_settings
                    : session.isTeacher
                        ? Icons.person
                        : Icons.school_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              session.userName ?? 'User',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              session.isAdmin
                  ? 'Administrator'
                  : session.isTeacher
                      ? 'Teacher'
                      : 'Student',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Role'),
                  trailing: Text(
                    session.isAdmin
                        ? 'Admin'
                        : session.isTeacher
                            ? 'Teacher'
                            : 'Student',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('User ID'),
                  trailing: Text('${session.userId ?? '-'}'),
                ),
                if (session.divisionId != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('Division'),
                    trailing: Text('${session.divisionId}'),
                  ),
                ],
                if (session.rollNumber != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tag),
                    title: const Text('Roll Number'),
                    trailing: Text('${session.rollNumber}'),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  trailing: Text(AppConstants.version),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isSchool) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined,
                        color: Colors.teal),
                    title: const Text('Cloud Sync (Google Sheets)'),
                    subtitle: const Text('Connect to your own Google Sheet'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.syncSettings.path),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.backup_outlined, color: Colors.indigo),
                    title: const Text('Backup & Restore'),
                    subtitle: const Text('Save or restore all data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.backupRestore.path),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.ios_share, color: Colors.purple),
                    title: const Text('Export Reports'),
                    subtitle: const Text('CSV for Excel / Google Sheets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.export.path),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Colors.red),
                    title: const Text('App Lock (PIN)'),
                    subtitle: const Text('Protect the app with a PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showPinSetupDialog(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirmed = await ConfirmationDialog(
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out?',
                  confirmLabel: 'Sign Out',
                  icon: Icons.logout,
                  isDestructive: false,
                ).show(context);

                if (confirmed && context.mounted) {
                  ref.read(authStateProvider.notifier).logout();
                  context.go(AppRoutes.login.path);
                }
              },
            ),
          ),
          if (session.isAdmin) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Data & Privacy',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All data is stored locally on this device. Use the backup & '
              'restore tools to keep copies safe. Google Sheets sync sends '
              'attendance and homework records only to the sheet you control.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (session.isStudent) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Privacy Note',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Students can only see their own attendance and assignments. '
              'No personal data ever leaves the device without the school '
              'administrator enabling cloud sync.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}