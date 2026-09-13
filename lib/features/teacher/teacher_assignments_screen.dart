import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../database/daos/homework_dao.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class TeacherAssignmentsScreen extends ConsumerWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    final teacherId = session.userId ?? 0;
    final assignmentsAsync =
        ref.watch(teacherAssignmentsProvider(teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Assignment',
            onPressed: () =>
                context.push(AppRoutes.teacherNewAssignment.path),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyStateWidget(
              message: 'No assignments yet',
              hint: 'Tap the + button to create one.',
              icon: Icons.assignment_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: assignments.length,
            itemBuilder: (context, index) =>
                _AssignmentTile(detail: assignments[index]),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: '$e'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.teacherNewAssignment.path),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AssignmentTile extends ConsumerWidget {
  final HomeworkAssignmentDetail detail;
  const _AssignmentTile({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignment = detail.assignment;
    final submissionsAsync =
        ref.watch(submissionsForAssignmentProvider(assignment.id));

    final count = submissionsAsync.value?.length ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => context.push(AppRoutes.teacherAssignmentDetail
            .build({'assignmentId': '${assignment.id}'})),
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withValues(alpha: 0.15),
          child: const Icon(Icons.assignment, color: Colors.purple),
        ),
        title: Text(
          assignment.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('Class ${detail.classData.name}-${detail.division.name}'),
            Text('Due: ${Formatters.formatDateTime(assignment.dueDate)}'),
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count submitted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'View →',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}