import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/daos/homework_dao.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class TeacherAssignmentDetailScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const TeacherAssignmentDetailScreen(
      {super.key, required this.assignmentId});

  @override
  ConsumerState<TeacherAssignmentDetailScreen> createState() =>
      _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState
    extends ConsumerState<TeacherAssignmentDetailScreen> {
  late Future<HomeworkAssignmentDetail?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref
        .read(homeworkDaoProvider)
        .getAssignmentWithDetails(widget.assignmentId);
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync =
        ref.watch(submissionsForAssignmentProvider(widget.assignmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: FutureBuilder<HomeworkAssignmentDetail?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const ErrorDisplay(message: 'Assignment not found');
          }
          final detail = snapshot.data!;
          final assignment = detail.assignment;

          return Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          'Class ${detail.classData.name}-${detail.division.name}'),
                      Text(
                          'Due: ${Formatters.formatDateTime(assignment.dueDate)}'),
                      if (assignment.description != null &&
                          assignment.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(assignment.description!),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: submissionsAsync.when(
                  data: (submissions) {
                    if (submissions.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'No submissions yet',
                        hint: 'Students will appear here after they submit.',
                        icon: Icons.inbox_outlined,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: submissions.length,
                      itemBuilder: (context, index) {
                        final item = submissions[index];
                        final late = item.submission.submittedAt
                            .isAfter(assignment.dueDate);
                        final color =
                            late ? AppTheme.lateColor : AppTheme.presentColor;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(
                                late
                                    ? Icons.schedule
                                    : Icons.check_circle_outline,
                                color: color,
                              ),
                            ),
                            title: Text(item.student.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Roll: ${item.student.rollNumber}'),
                                Text(
                                  'Submitted: '
                                  '${Formatters.formatDateTime(item.submission.submittedAt)}',
                                ),
                                if (item.submission.attachmentName != null)
                                  Text(
                                    'Attachment: ${item.submission.attachmentName}',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: StatusChip(
                              label: late ? 'Late' : 'Submitted',
                              color: color,
                            ),
                            onTap: () => _showSubmissionDialog(item),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => ErrorDisplay(message: '$e'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSubmissionDialog(HomeworkSubmissionWithStudent item) {
    final submission = item.submission;
    final feedbackController =
        TextEditingController(text: submission.feedback ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.student.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submission.submissionText != null &&
                    submission.submissionText!.isNotEmpty) ...[
                  Text('Answer',
                      style: Theme.of(dialogContext).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(submission.submissionText!),
                  const SizedBox(height: 12),
                ],
                if (submission.attachmentName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 18),
                      const SizedBox(width: 4),
                      Expanded(child: Text(submission.attachmentName!)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                Text('Feedback',
                    style: Theme.of(dialogContext).textTheme.titleSmall),
                const SizedBox(height: 4),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Feedback / grade'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(homeworkDaoProvider).setFeedback(
                    assignmentId: widget.assignmentId,
                    studentId: item.student.id,
                    feedback: feedbackController.text.trim(),
                  );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                await showAppSnackBar(context, 'Feedback saved');
              }
            },
            child: const Text('Save Feedback'),
          ),
        ],
      ),
    );
  }
}