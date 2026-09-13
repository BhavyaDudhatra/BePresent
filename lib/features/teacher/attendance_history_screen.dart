import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const AttendanceHistoryScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      lastDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 10),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_divisionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance History')),
        body: const LoadingIndicator(),
      );
    }

    final recordsAsync = ref.watch(
      attendanceForDivisionAndDateProvider(
        (divisionId: _divisionId!, date: _selectedDate),
      ),
    );

    final studentsAsync =
        ref.watch(studentsByDivisionProvider(_divisionId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Class $_className - Division $_divisionName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(Formatters.formatDate(_selectedDate)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No students in this division',
                    icon: Icons.people_outline,
                  );
                }
                return recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return EmptyStateWidget(
                        message: 'No attendance saved for this date',
                        hint: 'Attendance was not taken for '
                            '${Formatters.formatDate(_selectedDate)}',
                        icon: Icons.event_busy,
                      );
                    }
                    final sorted = [...records]
                      ..sort((a, b) => a.student.rollNumber
                          .compareTo(b.student.rollNumber));
                    return ListView.separated(
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final record = sorted[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _statusColor(record.status.name)
                                    .withValues(alpha: 0.15),
                            child: Text(
                              record.student.name.isNotEmpty
                                  ? record.student.name[0]
                                  : '?',
                              style: TextStyle(
                                color: _statusColor(record.status.name),
                              ),
                            ),
                          ),
                          title: Text(record.student.name),
                          subtitle:
                              Text('Roll No: ${record.student.rollNumber}'),
                          trailing: StatusChip(
                            label: record.status.label,
                            color: _statusColor(record.status.name),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => ErrorDisplay(message: '$e'),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorDisplay(message: '$e'),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.presentColor;
      case 'absent':
        return AppTheme.absentColor;
      case 'late':
        return AppTheme.lateColor;
      default:
        return Colors.grey;
    }
  }
}