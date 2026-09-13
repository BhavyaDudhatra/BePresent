import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/daos/attendance_dao.dart';
import '../../database/daos/student_dao.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class StudentAttendanceReportScreen extends ConsumerStatefulWidget {
  const StudentAttendanceReportScreen({super.key});

  @override
  ConsumerState<StudentAttendanceReportScreen> createState() =>
      _StudentAttendanceReportScreenState();
}

class _StudentAttendanceReportScreenState
    extends ConsumerState<StudentAttendanceReportScreen> {
  int? _selectedStudentId;
  late Future<List<StudentWithDetails>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<StudentWithDetails>> _loadStudents() async {
    final students = await ref.read(studentDaoProvider).getAllStudents();
    final withDetails = <StudentWithDetails>[];
    for (final s in students) {
      final detail = await ref.read(studentDaoProvider).getStudentWithDetails(s.id);
      if (detail != null) withDetails.add(detail);
    }
    return withDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Attendance Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<StudentWithDetails>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                final students = snapshot.data ?? [];
                return DropdownButtonFormField<int>(
                  initialValue: _selectedStudentId,
                  hint: const Text('Select Student'),
                  items: students.map((s) {
                    final cls = s.classData?.name ?? '';
                    final div = s.division?.name ?? '';
                    return DropdownMenuItem(
                      value: s.student.id,
                      child: Text(
                        '${s.student.name} (${cls}-$div)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedStudentId = v),
                );
              },
            ),
          ),
          Expanded(
            child: _selectedStudentId == null
                ? const EmptyStateWidget(
                    message: 'Select a student',
                    icon: Icons.person_search,
                  )
                : _ReportView(studentId: _selectedStudentId!),
          ),
        ],
      ),
    );
  }
}

class _ReportView extends ConsumerStatefulWidget {
  final int studentId;
  const _ReportView({required this.studentId});

  @override
  ConsumerState<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<_ReportView> {
  late Future<StudentWithDetails?> _studentFuture;
  late Future<AttendanceSummary> _allTimeSummaryFuture;
  late Future<AttendanceSummary> _monthSummaryFuture;
  late Future<List<AttendanceWithDetails>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _load();
    }
  }

  void _load() {
    final dao = ref.read(studentDaoProvider);
    final attendanceDao = ref.read(attendanceDaoProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    _studentFuture = dao.getStudentWithDetails(widget.studentId);
    _monthSummaryFuture = attendanceDao.getAttendanceSummary(
      widget.studentId,
      monthStart,
      now,
    );
    _allTimeSummaryFuture = attendanceDao.getAttendanceSummary(
      widget.studentId,
      DateTime(now.year - 5),
      now,
    );
    _historyFuture = attendanceDao.getAttendanceForStudent(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _studentFuture,
        _monthSummaryFuture,
        _allTimeSummaryFuture,
        _historyFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return ErrorDisplay(message: '${snapshot.error}');
        }
        final results = snapshot.data as List;
        final student = results[0] as StudentWithDetails?;
        final monthSummary = results[1] as AttendanceSummary;
        final allTime = results[2] as AttendanceSummary;
        final history = results[3] as List<AttendanceWithDetails>;

        if (student == null) {
          return const ErrorDisplay(message: 'Student not found');
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.student.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class ${student.classData?.name ?? '?'} - '
                      'Division ${student.division?.name ?? '?'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Roll No: ${student.student.rollNumber}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            _SummaryGrid(summary: allTime),
            const SizedBox(height: 8),
            Text(
              'This Month (${Formatters.formatMonthYear(DateTime.now())})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _SummaryGrid(summary: monthSummary),
            const SizedBox(height: 16),
            _AttendanceDonutChart(
              present: monthSummary.presentDays,
              absent: monthSummary.absentDays,
              late: monthSummary.lateDays,
            ),
            const SizedBox(height: 16),
            Text(
              'Attendance History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const EmptyStateWidget(
                message: 'No attendance records',
                icon: Icons.event_busy,
              )
            else
              ...history.map((record) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(record.status.name)
                          .withValues(alpha: 0.15),
                      child: Icon(
                        _statusIcon(record.status.name),
                        color: _statusColor(record.status.name),
                      ),
                    ),
                    title: Text(Formatters.formatDate(record.attendance.date)),
                    subtitle: Text(Formatters.formatDay(record.attendance.date)),
                    trailing: StatusChip(
                      label: record.status.label,
                      color: _statusColor(record.status.name),
                    ),
                  ),
                );
              }),
          ],
        );
      },
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}

class _SummaryGrid extends StatelessWidget {
  final AttendanceSummary summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Present', '${summary.presentDays}', AppTheme.presentColor),
      ('Absent', '${summary.absentDays}', AppTheme.absentColor),
      ('Late', '${summary.lateDays}', AppTheme.lateColor),
      ('% Present', summary.percentage.toStringAsFixed(1), Colors.blue),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: items.map((item) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.$2,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: item.$3,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              item.$1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _AttendanceDonutChart extends StatelessWidget {
  final int present;
  final int absent;
  final int late;
  const _AttendanceDonutChart({
    required this.present,
    required this.absent,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    final total = present + absent + late;
    if (total == 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: present.toDouble(),
        color: AppTheme.presentColor,
        title: '${(present / total * 100).toStringAsFixed(0)}%',
        radius: 55,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      if (absent > 0)
        PieChartSectionData(
          value: absent.toDouble(),
          color: AppTheme.absentColor,
          title: '${(absent / total * 100).toStringAsFixed(0)}%',
          radius: 55,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      if (late > 0)
        PieChartSectionData(
          value: late.toDouble(),
          color: AppTheme.lateColor,
          title: '${(late / total * 100).toStringAsFixed(0)}%',
          radius: 55,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Monthly Attendance Distribution',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LegendItem(label: 'Present', color: AppTheme.presentColor),
                const SizedBox(width: 12),
                _LegendItem(label: 'Absent', color: AppTheme.absentColor),
                if (late > 0) ...[
                  const SizedBox(width: 12),
                  _LegendItem(label: 'Late', color: AppTheme.lateColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}