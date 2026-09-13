import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/app_database.dart';
import '../../database/daos/homework_dao.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class StudentAssignmentsScreen extends ConsumerWidget {
  final bool embedded;
  const StudentAssignmentsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    final divisionId = session.divisionId ?? 0;
    final studentId = session.userId ?? 0;

    final assignmentsAsync =
        ref.watch(assignmentsForDivisionProvider(divisionId));
    final mySubmissionsAsync = ref.watch(mySubmissionsProvider(studentId));

    Widget body = assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return const EmptyStateWidget(
            message: 'No homework assigned',
            hint: 'Your teacher has not posted any homework yet.',
            icon: Icons.assignment_outlined,
          );
        }
        final submissions = mySubmissionsAsync.value ?? [];
        final byAssignment = {for (final s in submissions) s.assignmentId: s};
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final detail = assignments[index];
            final submission = byAssignment[detail.assignment.id];
            return _AssignmentCard(
              detail: detail,
              submission: submission,
              onTap: () => context.push(AppRoutes.studentAssignmentDetail
                  .build({'assignmentId': '${detail.assignment.id}'})),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(message: '$e'),
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('My Homework')),
      body: body,
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final HomeworkAssignmentDetail detail;
  final HomeworkSubmission? submission;
  final VoidCallback onTap;
  const _AssignmentCard({
    required this.detail,
    required this.submission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assignment = detail.assignment;
    final sub = submission;
    final isLate =
        sub != null && sub.submittedAt.isAfter(assignment.dueDate);
    final isMissing = sub == null && DateTime.now().isAfter(assignment.dueDate);
    final statusColor = sub == null
        ? (isMissing ? AppTheme.absentColor : Colors.blue)
        : (isLate ? AppTheme.lateColor : AppTheme.presentColor);
    final statusLabel = sub == null
        ? (isMissing ? 'Missing' : 'Pending')
        : (isLate ? 'Late' : 'Submitted');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            submission == null ? Icons.assignment_outlined : Icons.assignment_turned_in,
            color: statusColor,
          ),
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
        trailing: StatusChip(label: statusLabel, color: statusColor),
      ),
    );
  }
}