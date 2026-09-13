import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _busy = false;

  Future<void> _export(String kind) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(exportServiceProvider);
      final file = switch (kind) {
        'attendance' => await service.exportAttendance(),
        'students' => await service.exportStudents(),
        'homework' => await service.exportHomework(),
        _ => throw ArgumentError('Unknown export kind: $kind'),
      };
      await service.shareFile(file, subject: _label(kind));
    } catch (e) {
      if (mounted) {
        await showAppSnackBar(context, 'Export failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(String kind) => switch (kind) {
        'attendance' => 'Attendance Export',
        'students' => 'Students Export',
        'homework' => 'Homework Export',
        _ => 'Export',
      };

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Attendance',
        'All attendance records as CSV',
        Icons.checklist_outlined,
        Colors.green,
        'attendance',
      ),
      (
        'Students',
        'Student directory with guardians',
        Icons.people_outline,
        Colors.blue,
        'students',
      ),
      (
        'Homework',
        'Assignments and submissions',
        Icons.assignment_outlined,
        Colors.purple,
        'homework',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Export Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Export data as CSV (opens in Excel / Google Sheets) and share '
                'it anywhere - Google Drive, email, messaging apps.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.$4.withValues(alpha: 0.15),
                  child: Icon(item.$3, color: item.$4),
                ),
                title: Text(item.$1),
                subtitle: Text(item.$2),
                trailing: const Icon(Icons.ios_share),
                onTap: _busy ? null : () => _export(item.$5),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (_busy) const LoadingIndicator(),
        ],
      ),
    );
  }
}