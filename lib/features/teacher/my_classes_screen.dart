import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    final teacherId = session.userId ?? 0;

    final assignmentsAsync =
        ref.watch(assignmentsForTeacherProvider(teacherId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Classes')),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyStateWidget(
              message: 'No classes assigned',
              hint: 'Please contact the school administrator '
                  'to get your class assignments.',
              icon: Icons.class_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _AssignmentCard(
                assignmentId: assignment.id,
                classId: assignment.classId,
                divisionId: assignment.divisionId,
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: '$e'),
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final int assignmentId;
  final int classId;
  final int divisionId;
  const _AssignmentCard({
    required this.assignmentId,
    required this.classId,
    required this.divisionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classAsync = ref.watch(
      classDetailProvider((classId: classId, divisionId: divisionId)),
    );

    return classAsync.when(
      data: (detail) {
        final title = 'Class ${detail.cls.name} - Division ${detail.division.name}';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: Text(
                        detail.cls.name,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionChip(
                      icon: Icons.checklist,
                      color: Colors.green,
                      label: 'Take Attendance',
                      onTap: () => context.push(
                        AppRoutes.teacherAttendance
                            .build({'assignmentId': '$assignmentId'}),
                      ),
                    ),
                    _ActionChip(
                      icon: Icons.history,
                      color: Colors.orange,
                      label: 'History',
                      onTap: () => context.push(
                        AppRoutes.teacherHistory
                            .build({'assignmentId': '$assignmentId'}),
                      ),
                    ),
                    _ActionChip(
                      icon: Icons.people_outline,
                      color: Colors.purple,
                      label: 'Students',
                      onTap: () => context.push(
                        AppRoutes.teacherStudents
                            .build({'assignmentId': '$assignmentId'}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: CircularProgressIndicator(strokeWidth: 2),
          title: Text('Loading...'),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
      onPressed: onTap,
    );
  }
}