import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class ManageTeachersScreen extends ConsumerWidget {
  const ManageTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(allTeachersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Teachers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminAddTeacher.path),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Teacher'),
      ),
      body: teachersAsync.when(
        data: (teachers) {
          if (teachers.isEmpty) {
            return const EmptyStateWidget(
              message: 'No teachers yet',
              hint: 'Tap "Add Teacher" to add teachers',
              icon: Icons.badge_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      teacher.isActive
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_outline,
                    color: teacher.isActive ? Colors.orange : Colors.grey,
                  ),
                ),
                title: Text(
                  teacher.name,
                  style: teacher.isActive
                      ? null
                      : TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                ),
                subtitle: Text('@${teacher.username}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!teacher.isActive)
                      const StatusChip(label: 'Inactive', color: Colors.grey),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(
                        AppRoutes.adminEditTeacher
                            .build({'teacherId': '${teacher.id}'}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _deleteTeacher(context, ref, teacher),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: '$e'),
      ),
    );
  }

  Future<void> _deleteTeacher(
    BuildContext context,
    WidgetRef ref,
    Teacher teacher,
  ) async {
    final confirmed = await ConfirmationDialog(
      title: 'Delete Teacher',
      message:
          'Delete ${teacher.name}? This will remove their class assignments but '
          'their attendance records will be preserved.',
    ).show(context);

    if (!confirmed || !context.mounted) return;

    try {
      final assignments = await ref
          .read(teacherDaoProvider)
          .getAssignmentsForTeacher(teacher.id);
      for (final a in assignments) {
        await ref.read(teacherDaoProvider).removeTeacherClassAssignment(a.id);
      }
      await ref.read(teacherDaoProvider).deleteTeacher(teacher.id);
      if (context.mounted) {
        await showAppSnackBar(context, 'Teacher deleted');
      }
    } catch (e) {
      if (context.mounted) {
        await showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }
}