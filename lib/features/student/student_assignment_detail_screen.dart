import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/daos/homework_dao.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class StudentAssignmentDetailScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const StudentAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends ConsumerState<StudentAssignmentDetailScreen> {
  final _textController = TextEditingController();
  String? _attachmentPath;
  String? _attachmentName;
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final session = ref.read(authStateProvider);
    final studentId = session.userId ?? 0;
    final existing = await ref
        .read(homeworkDaoProvider)
        .getMySubmission(widget.assignmentId, studentId);
    if (!mounted) return;
    if (existing != null) {
      _textController.text = existing.submissionText ?? '';
      _attachmentPath = existing.attachmentPath;
      _attachmentName = existing.attachmentName;
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (result.isEmpty || result.first.path == null) return;
    final pickedPath = result.first.path!;
    final name = p.basename(pickedPath);

    // Copy to app documents so the attachment survives cache clears.
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(dir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    final target =
        p.join(attachmentsDir.path, '${DateTime.now().millisecondsSinceEpoch}_$name');
    await File(pickedPath).copy(target);

    if (!mounted) return;
    setState(() {
      _attachmentPath = target;
      _attachmentName = name;
    });
  }

  Future<void> _submit() async {
    final session = ref.read(authStateProvider);
    final studentId = session.userId ?? 0;
    final text = _textController.text.trim();
    if (text.isEmpty && _attachmentPath == null) {
      await showAppSnackBar(
          context, 'Write something or attach a file first', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dao = ref.read(homeworkDaoProvider);
      await dao.upsertSubmission(
        assignmentId: widget.assignmentId,
        studentId: studentId,
        text: text.isEmpty ? null : text,
        attachmentPath: _attachmentPath,
        attachmentName: _attachmentName,
      );

      unawaited(_syncSubmission(studentId));
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showAppSnackBar(context, 'Submitted successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showAppSnackBar(context, 'Submission failed: $e', isError: true);
    }
  }

  Future<void> _syncSubmission(int studentId) async {
    try {
      final dao = ref.read(homeworkDaoProvider);
      final saved = await dao.getMySubmission(widget.assignmentId, studentId);
      final detail = await dao.getAssignmentWithDetails(widget.assignmentId);
      final student =
          await ref.read(studentDaoProvider).getStudentById(studentId);
      if (saved != null && detail != null && student != null) {
        await ref.read(cloudSyncServiceProvider).pushSubmission(
              HomeworkSubmissionSync(
                submission: saved,
                student: student,
                assignment: detail.assignment,
              ),
            );
      }
    } catch (_) {
      // Cloud sync is best-effort; ignore failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      body: _loaded
          ? _buildBody(context)
          : const LoadingIndicator(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Submit Answer',
            icon: Icons.send,
            isLoading: _isSaving,
            backgroundColor: Colors.green,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final assignmentsAsync =
        ref.watch(assignmentsForDivisionProvider(ref.read(authStateProvider).divisionId ?? 0));

    return assignmentsAsync.when(
      data: (assignments) {
        final detail = assignments
            .where((a) => a.assignment.id == widget.assignmentId)
            .firstOrNull;
        if (detail == null) {
          return const ErrorDisplay(message: 'Assignment not found');
        }
        final assignment = detail.assignment;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              assignment.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.class_outlined,
              label: 'Class ${detail.classData.name}-${detail.division.name}',
            ),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Teacher: ${detail.teacher.name}',
            ),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Due: ${Formatters.formatDateTime(assignment.dueDate)}',
              color: DateTime.now().isAfter(assignment.dueDate)
                  ? AppTheme.absentColor
                  : null,
            ),
            if (assignment.description != null &&
                assignment.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instructions',
                          style:
                              Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(assignment.description!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Your Answer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Type your answer',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file),
              label: Text(_attachmentName ?? 'Attach a file or photo'),
            ),
            if (_attachmentPath != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _attachmentName ?? 'Attachment stored locally',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _attachmentPath = null;
                      _attachmentName = null;
                    }),
                  ),
                ],
              ),
            ],
            if (_hasSubmitted()) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.presentColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.presentColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                            'You have already submitted this homework. You can update it.'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(message: '$e'),
    );
  }

  bool _hasSubmitted() {
    return _attachmentName != null || _textController.text.trim().isNotEmpty;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}