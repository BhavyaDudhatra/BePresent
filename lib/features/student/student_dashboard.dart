import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../database/daos/attendance_dao.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';
import '../common/profile_screen.dart';
import 'student_assignments_screen.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _StudentHomeTab(),
      const StudentAssignmentsScreen(embedded: true),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StudentHomeTab extends ConsumerWidget {
  const _StudentHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider);
    final studentId = session.userId ?? 0;
    final divisionId = session.divisionId ?? 0;

    final now = DateTime.now();
    final allTimeSummary =
        ref.watch(_studentSummaryProvider((student: studentId, end: now)));

    final assignmentsAsync =
        ref.watch(assignmentsForDivisionProvider(divisionId));
    final mySubmissionsAsync = ref.watch(mySubmissionsProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.profile.path),
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_studentSummaryProvider(
              (student: studentId, end: now)));
          ref.invalidate(assignmentsForDivisionProvider(divisionId));
          ref.invalidate(mySubmissionsProvider(studentId));
        },
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${session.userName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your attendance at a glance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            allTimeSummary.when(
              data: (summary) => _AttendanceWidget(summary: summary),
              loading: () => const Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: LoadingIndicator(),
              ),
              error: (e, _) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ErrorDisplay(message: '$e'),
              ),
            ),
            const SizedBox(height: 4),
            assignmentsAsync.when(
              data: (assignments) {
                final submissions = mySubmissionsAsync.value ?? [];
                final byAssignment = {
                  for (final s in submissions) s.assignmentId: s,
                };
                int pending = 0, submitted = 0, overdue = 0;
                for (final a in assignments) {
                  final sub = byAssignment[a.assignment.id];
                  if (sub == null) {
                    if (DateTime.now().isAfter(a.assignment.dueDate)) {
                      overdue++;
                    } else {
                      pending++;
                    }
                  } else {
                    submitted++;
                  }
                }
                return _HomeworkOverview(
                  pending: pending,
                  submitted: submitted,
                  overdue: overdue,
                  total: assignments.length,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Reports',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _menuItem(
              context,
              'My Attendance Report',
              'Full history, statistics and charts',
              Icons.assessment_outlined,
              Colors.green,
              () => context.push(AppRoutes.studentAttendance.path),
            ),
            _menuItem(
              context,
              'My Homework',
              'Pending and submitted assignments',
              Icons.assignment_outlined,
              Colors.purple,
              () => context.push(AppRoutes.studentAssignments.path),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

final _studentSummaryProvider = FutureProvider.autoDispose
    .family<AttendanceSummary, ({int student, DateTime end})>((ref, args) {
  return ref
      .read(attendanceDaoProvider)
      .getAttendanceSummary(args.student, DateTime(2000), args.end);
});

class _AttendanceWidget extends StatelessWidget {
  final AttendanceSummary summary;
  const _AttendanceWidget({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.totalDays;
    final pct = total > 0 ? summary.percentage : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: (total > 0
                                    ? summary.presentDays
                                    : 1)
                                .toDouble(),
                            color: AppTheme.presentColor,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 48,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (summary.absentDays > 0)
                            PieChartSectionData(
                              value: summary.absentDays.toDouble(),
                              color: AppTheme.absentColor,
                              radius: 48,
                              titleStyle: const TextStyle(fontSize: 0),
                            ),
                          if (summary.lateDays > 0)
                            PieChartSectionData(
                              value: summary.lateDays.toDouble(),
                              color: AppTheme.lateColor,
                              radius: 48,
                              titleStyle: const TextStyle(fontSize: 0),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _row(context, 'Present', '${summary.presentDays}',
                          AppTheme.presentColor),
                      const SizedBox(height: 8),
                      _row(context, 'Absent', '${summary.absentDays}',
                          AppTheme.absentColor),
                      const SizedBox(height: 8),
                      _row(context, 'Late', '${summary.lateDays}',
                          AppTheme.lateColor),
                      const SizedBox(height: 8),
                      _row(context, 'Days recorded', '$total', Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.studentAttendance.path),
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('View Full Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _HomeworkOverview extends StatelessWidget {
  final int pending;
  final int submitted;
  final int overdue;
  final int total;
  const _HomeworkOverview({
    required this.pending,
    required this.submitted,
    required this.overdue,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Homework', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.studentAssignments.path),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                    label: pending == 0 ? 'No pending' : '$pending pending',
                    color: Colors.blue),
                StatusChip(
                    label: '$submitted submitted', color: AppTheme.presentColor),
                if (overdue > 0)
                  StatusChip(
                      label: '$overdue overdue',
                      color: AppTheme.absentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}