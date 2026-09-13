import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/daos/attendance_dao.dart';
import '../../database/daos/class_dao.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class AttendanceOverviewScreen extends ConsumerStatefulWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  ConsumerState<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState
    extends ConsumerState<AttendanceOverviewScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedDivisionId;
  late Future<List<DivisionWithClass>> _divisionsFuture;

  @override
  void initState() {
    super.initState();
    _divisionsFuture = ref.read(classDaoProvider).getAllDivisionsWithClass();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Overview')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<DivisionWithClass>>(
                    future: _divisionsFuture,
                    builder: (context, snapshot) {
                      final divisions = snapshot.data ?? [];
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedDivisionId,
                        hint: const Text('Select Class / Division'),
                        items: divisions
                            .map((d) => DropdownMenuItem(
                                  value: d.division.id,
                                  child: Text('Class ${d.classData.name} - '
                                      'Division ${d.division.name}'),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedDivisionId = v),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(Formatters.formatShortDate(_selectedDate)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDivisionId == null
                ? const EmptyStateWidget(
                    message: 'Select a class/division',
                    hint: 'Attendance overview will appear here',
                    icon: Icons.calendar_month_outlined,
                  )
                : _DivisionAttendanceView(
                    divisionId: _selectedDivisionId!,
                    date: _selectedDate,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DivisionAttendanceView extends ConsumerStatefulWidget {
  final int divisionId;
  final DateTime date;
  const _DivisionAttendanceView({
    required this.divisionId,
    required this.date,
  });

  @override
  ConsumerState<_DivisionAttendanceView> createState() =>
      _DivisionAttendanceViewState();
}

class _DivisionAttendanceViewState
    extends ConsumerState<_DivisionAttendanceView> {
late Future<AttendanceSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DivisionAttendanceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.divisionId != widget.divisionId ||
        oldWidget.date != widget.date) {
      _load();
    }
  }

  void _load() {
    setState(() {
      _summaryFuture = ref
          .read(attendanceDaoProvider)
          .getDivisionAttendanceSummary(widget.divisionId, widget.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(
      attendanceForDivisionAndDateProvider(
        (divisionId: widget.divisionId, date: widget.date),
      ),
    );

    return Column(
      children: [
        FutureBuilder<AttendanceSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            final s = snapshot.data;
            if (s == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Present',
                      value: '${s.presentDays}',
                      color: AppTheme.presentColor,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Absent',
                      value: '${s.absentDays}',
                      color: AppTheme.absentColor,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Late',
                      value: '${s.lateDays}',
                      color: AppTheme.lateColor,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: '% Present',
                      value: s.percentage.toStringAsFixed(0),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: attendanceAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return EmptyStateWidget(
                  message: 'No attendance recorded',
                  hint: 'Attendance for ${Formatters.formatDate(widget.date)} '
                      'has not been taken yet',
                  icon: Icons.event_busy,
                );
              }
              records.sort((a, b) => a.student.rollNumber
                  .compareTo(b.student.rollNumber));
              return ListView.separated(
                itemCount: records.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(record.status.name).withValues(alpha: 0.15),
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
                    subtitle: Text('Roll No: ${record.student.rollNumber}'),
                    trailing: StatusChip(
                      label: record.status.label,
                      color: _statusColor(record.status.name),
                    ),
                    onTap: () => context.push(
                      AppRoutes.teacherStudentReport
                          .build({'studentId': '${record.student.id}'}),
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}