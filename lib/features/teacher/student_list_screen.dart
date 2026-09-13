import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const StudentListScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<StudentListScreen> createState() =>
      _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  int? _divisionId;
  String? _className;
  String? _divisionName;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final teacherDao = ref.read(teacherDaoProvider);
    final classDao = ref.read(classDaoProvider);

    final assignments = await teacherDao.getAllAssignments();
    for (final a in assignments) {
      final teacherAssignments =
          await teacherDao.getAssignmentsForTeacher(a.teacherId);
      final found =
          teacherAssignments.where((t) => t.id == widget.assignmentId);
      if (found.isNotEmpty) {
        final match = found.first;
        final cls = await classDao.getClassById(match.classId);
        final div = await classDao.getDivisionById(match.divisionId);
        if (mounted) {
          setState(() {
            _divisionId = match.divisionId;
            _className = cls?.name;
            _divisionName = div?.name;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_divisionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Students')),
        body: const LoadingIndicator(),
      );
    }

    final studentsAsync = ref.watch(
      studentsByDivisionProvider(_divisionId!),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Class $_className - Division $_divisionName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ),
        ),
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const EmptyStateWidget(
              message: 'No students in this division',
              icon: Icons.people_outline,
            );
          }
          return ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                title: Text(student.name),
                subtitle: Text('Roll No: ${student.rollNumber}'),
                trailing: Text(
                  Formatters.formatShortDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                onTap: () => context.push(
                  AppRoutes.teacherStudentReport
                      .build({'studentId': '${student.id}'}),
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
}