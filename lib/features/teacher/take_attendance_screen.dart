import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const TakeAttendanceScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<int, String> _statusMap = {};
  bool _isSaving = false;
  int? _divisionId;
  int? _teacherId;
  String? _className;
  String? _divisionName;
  late int _presentStatusId;
  late int _absentStatusId;
  late int _lateStatusId;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      final teacherDao = ref.read(teacherDaoProvider);
      final classDao = ref.read(classDaoProvider);

      final assignments = await teacherDao.getAllAssignments();
      TeacherClassAssignment? match;
      for (final a in assignments) {
        final teacherAssignments =
            await teacherDao.getAssignmentsForTeacher(a.teacherId);
        final found =
            teacherAssignments.where((t) => t.id == widget.assignmentId);
        if (found.isNotEmpty) {
          match = found.first;
          break;
        }
      }

if (match == null || !mounted) return;

      final assignment = match;
      final cls = await classDao.getClassById(assignment.classId);
      final div = await classDao.getDivisionById(assignment.divisionId);

      final statuses = await ref.read(attendanceDaoProvider).getAllStatuses();
      _presentStatusId =
          statuses.firstWhere((s) => s.name == 'present').id;
      _absentStatusId =
          statuses.firstWhere((s) => s.name == 'absent').id;
      _lateStatusId = statuses.firstWhere((s) => s.name == 'late').id;

      if (!mounted) return;
      setState(() {
        _divisionId = assignment.divisionId;
        _teacherId = assignment.teacherId;
        _className = cls?.name;
        _divisionName = div?.name;
      });

      _loadExistingAttendance();
    } catch (e) {
      if (mounted) {
        await showAppSnackBar(context, 'Error loading: $e', isError: true);
      }
    }
  }

  Future<void> _loadExistingAttendance() async {
    if (_divisionId == null) return;
    final attendanceDao = ref.read(attendanceDaoProvider);
    final studentDao = ref.read(studentDaoProvider);

    final students = await studentDao.getStudentsByDivision(_divisionId!);
    final existing = await attendanceDao
        .getAttendanceForDivisionAndDate(_divisionId!, _selectedDate);

    if (!mounted) return;
    setState(() {
      _statusMap = {for (final s in students) s.id: '$_presentStatusId'};
      for (final record in existing) {
        _statusMap[record.studentId] = '${record.statusId}';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime.now(),
      helpText: 'Select Attendance Date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (_divisionId == null || _teacherId == null) return;

    setState(() => _isSaving = true);

    try {
      final dao = ref.read(attendanceDaoProvider);
      final statusMap = _statusMap.map((k, v) {
        return MapEntry(k, int.parse(v));
      });

      await dao.saveAttendance(
        divisionId: _divisionId!,
        teacherId: _teacherId!,
        date: _selectedDate,
        studentStatusMap: statusMap,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        await showAppSnackBar(context, 'Attendance saved successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await showAppSnackBar(context, 'Save failed: $e', isError: true);
      }
    }
  }

  void _setStatus(int studentId, String statusId) {
    setState(() => _statusMap[studentId] = statusId);
  }

  void _markAllPresent() {
    setState(() {
      for (final key in _statusMap.keys.toList()) {
        _statusMap[key] = '$_presentStatusId';
      }
    });
  }

  String _displayName(int id) {
    if (id == _presentStatusId) return 'present';
    if (id == _absentStatusId) return 'absent';
    if (id == _lateStatusId) return 'late';
    return 'present';
  }

  @override
  Widget build(BuildContext context) {
    if (_divisionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Take Attendance')),
        body: const LoadingIndicator(),
      );
    }

    final studentsAsync =
        ref.watch(studentsByDivisionProvider(_divisionId!));

    return Scaffold(
      appBar: AppBar(title: Text('Take Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class $_className - Division $_divisionName',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All students default to Present',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(Formatters.formatDate(_selectedDate)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _markAllPresent,
                            child:
                                const Text('Mark All Present'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No students in this division',
                    icon: Icons.people_outline,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final statusId = _statusMap[student.id] ?? '$_presentStatusId';
                    return _AttendanceRow(
                      studentName: student.name,
                      rollNumber: student.rollNumber,
                      statusId: statusId,
                      presentId: _presentStatusId,
                      absentId: _absentStatusId,
                      lateId: _lateStatusId,
                      statusName: _displayName(int.parse(statusId)),
                      onChanged: (value) => _setStatus(student.id, value),
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorDisplay(message: '$e'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Save & Submit Attendance',
            icon: Icons.save,
            isLoading: _isSaving,
            backgroundColor: Colors.green,
            onPressed: () => _confirmAndSave(context),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndSave(BuildContext context) async {
    if (_statusMap.isEmpty) {
      await showAppSnackBar(context, 'No students to save', isError: true);
      return;
    }

    final presentCount = _statusMap.values
        .where((v) => v == '$_presentStatusId')
        .length;
    final absentCount = _statusMap.values
        .where((v) => v == '$_absentStatusId')
        .length;
    final lateCount = _statusMap.values
        .where((v) => v == '$_lateStatusId')
        .length;

    final confirmed = await ConfirmationDialog(
      title: 'Save Attendance',
message: 'Class $_className-$_divisionName\n'
          'Date: ${Formatters.formatDate(_selectedDate)}\n'
          '\n'
          'Present: $presentCount\n'
          'Absent: $absentCount\n'
          'Late: $lateCount\n'
          '\n'
          'Save this attendance?',
      confirmLabel: 'Save',
      icon: Icons.check_circle,
      isDestructive: false,
    ).show(context);

    if (confirmed) {
      await _saveAttendance();
    }
  }
}

class _AttendanceRow extends StatelessWidget {
  final String studentName;
  final String rollNumber;
  final String statusId;
  final int presentId;
  final int absentId;
  final int lateId;
  final String statusName;
  final void Function(String) onChanged;

  const _AttendanceRow({
    required this.studentName,
    required this.rollNumber,
    required this.statusId,
    required this.presentId,
    required this.absentId,
    required this.lateId,
    required this.statusName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(statusName);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.withValues(alpha: 0.15),
        child: Text(
          studentName.isNotEmpty ? studentName[0] : '?',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
      title: Text(studentName),
      subtitle: Text('Roll No: $rollNumber'),
      trailing: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: '$presentId',
            label: Text(
              'P',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const SizedBox.shrink(),
          ),
          ButtonSegment(
            value: '$absentId',
            label: const Text(
              'A',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          ButtonSegment(
            value: '$lateId',
            label: const Text(
              'L',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        selected: {statusId},
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return color;
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return color;
          }),
        ),
        onSelectionChanged: (selection) =>
            onChanged(selection.first),
      ),
    );
  }

  Color _getColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.presentColor;
      case 'absent':
        return AppTheme.absentColor;
      case 'late':
        return AppTheme.lateColor;
      default:
        return AppTheme.presentColor;
    }
  }
}

