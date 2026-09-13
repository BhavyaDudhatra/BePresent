import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/daos/attendance_dao.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../common/profile_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider);

    final screens = [
      Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
            ref.invalidate(authStateProvider);
          },
child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _GreetingCard(session: session),
              const _SchoolWideOverview(),
              _buildAdminMenu(context),
            ],
          ),
        ),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('Attendance Overview')),
        body: const Center(
          child: Text('Attendance Overview Loading...'),
        ),
      ),
      Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const ProfileScreen(),
      ),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Attendance',
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

  Widget _buildAdminMenu(BuildContext context) {
    final menus = [
      _AdminMenuItem(
        title: 'Manage Classes',
        subtitle: 'Add, edit and organize classes',
        icon: Icons.class_outlined,
        color: Colors.blue,
        route: AppRoutes.adminClasses,
      ),
      _AdminMenuItem(
        title: 'Manage Divisions',
        subtitle: 'Create divisions/sections',
        icon: Icons.grid_view_outlined,
        color: Colors.teal,
        route: AppRoutes.adminDivisions,
      ),
      _AdminMenuItem(
        title: 'Manage Students',
        subtitle: 'Add, edit and assign students',
        icon: Icons.people_outline,
        color: Colors.green,
        route: AppRoutes.adminStudents,
      ),
      _AdminMenuItem(
        title: 'Manage Teachers',
        subtitle: 'Add, edit and deactivate teachers',
        icon: Icons.badge_outlined,
        color: Colors.orange,
        route: AppRoutes.adminTeachers,
      ),
      _AdminMenuItem(
        title: 'Assign Teachers',
        subtitle: 'Assign teachers to classes/divisions',
        icon: Icons.how_to_reg_outlined,
        color: Colors.purple,
        route: AppRoutes.adminAssignTeachers,
      ),
_AdminMenuItem(
        title: 'Attendance Overview',
        subtitle: 'View daily attendance and reports',
        icon: Icons.calendar_month_outlined,
        color: Colors.red,
        route: AppRoutes.adminAttendanceOverview,
      ),
      _AdminMenuItem(
        title: 'Send Attendance Reports',
        subtitle: 'Message all parents about daily attendance',
        icon: Icons.sms_outlined,
        color: Colors.cyan,
        route: AppRoutes.adminSendMessage,
      ),
      _AdminMenuItem(
        title: 'School Settings',
        subtitle: 'Manage school information',
        icon: Icons.settings_outlined,
        color: Colors.indigo,
        route: AppRoutes.adminSchoolSettings,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...menus.map(
          (menu) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: menu.color.withValues(alpha: 0.15),
                child: Icon(menu.icon, color: menu.color),
              ),
              title: Text(menu.title),
              subtitle: Text(menu.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(menu.route.path),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final AuthSession session;
  const _GreetingCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final name = session.userName ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $name',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Today is ${Formatters.formatDate(DateTime.now())}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

final _weeklySummaryProvider = FutureProvider.autoDispose
    .family<List<({DateTime date, AttendanceSummary summary})>, DateTime>(
        (ref, endDate) {
  return ref.read(attendanceDaoProvider).getSchoolWideWeeklySummaries(endDate);
});

class _SchoolWideOverview extends ConsumerWidget {
  const _SchoolWideOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final weeklyAsync = ref.watch(_weeklySummaryProvider(today));

    return weeklyAsync.when(
      data: (weekly) {
        final todaySummary = weekly.isNotEmpty ? weekly.last.summary : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'School Stats',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (todaySummary != null)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Present Today',
                      value: '${todaySummary.presentDays}',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.presentColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Absent Today',
                      value: '${todaySummary.absentDays}',
                      icon: Icons.cancel_outlined,
                      color: AppTheme.absentColor,
                    ),
                  ),
                ],
              ),
            if (todaySummary != null)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Late Today',
                      value: '${todaySummary.lateDays}',
                      icon: Icons.schedule,
                      color: AppTheme.lateColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Overall % Present',
                      value: todaySummary.percentage.toStringAsFixed(0),
                      icon: Icons.percent,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            _WeeklyChart(weekly: weekly),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: LoadingIndicator(),
        ),
      ),
      error: (e, _) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Stats unavailable: $e'),
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<({DateTime date, AttendanceSummary summary})> weekly;
  const _WeeklyChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance % — Last 7 Days',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 25,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= weekly.length) {
                            return const SizedBox.shrink();
                          }
                          final day = Formatters.dayFormat
                              .format(weekly[index].date)
                              .substring(0, 3);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              day,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < weekly.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: weekly[i].summary.percentage,
                            color: AppTheme.presentColor,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppRoutes route;

  _AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
required this.route,
  });
}