import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _busy = false;

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).shareBackup();
    } catch (e) {
      if (mounted) {
        await showAppSnackBar(context, 'Backup failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
    );
    if (result.isEmpty || result.first.path == null) return;

    final path = result.first.path!;
    final confirmed = await ConfirmationDialog(
      title: 'Restore Backup?',
      message: 'This will replace all current data with the backup file. '
          'The current database is saved as a recovery copy.\n\n'
          'Continue?',
      confirmLabel: 'Restore',
      icon: Icons.restore,
      isDestructive: true,
    ).show(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final ok = await ref.read(backupServiceProvider).restoreFrom(path);
      if (!mounted) return;
      if (ok) {
        await showAppSnackBar(context, 'Database restored');
        ref.invalidate(authStateProvider);
      } else {
        await showAppSnackBar(context,
            'That file is not a valid Be Present backup', isError: true);
      }
    } catch (e) {
      if (mounted) {
        await showAppSnackBar(context, 'Restore failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Backups are complete SQLite database snapshots you can '
                    'export, save to Google Drive, or share. Restore replaces '
                    'the database on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Create Backup & Share',
            icon: Icons.backup_outlined,
            isLoading: _busy,
            backgroundColor: Colors.indigo,
            onPressed: _backup,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Restore from Backup File',
            icon: Icons.restore,
            isLoading: _busy,
            backgroundColor: Colors.orange,
            onPressed: _restore,
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: exported backup files end in .db and can be stored anywhere '
            '(Drive, OneDrive, email). Store them safely — they contain all '
            'school records.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}