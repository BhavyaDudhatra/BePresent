import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../services/auth_service.dart';
import '../common/profile_screen.dart';
import 'my_classes_screen.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider);

    final pages = <Widget>[
      _HomeTab(session: session, teacherId: session.userId ?? 0),
      const _ClassesTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Classes',
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

class _HomeTab extends ConsumerWidget {
  final AuthSession session;
  final int teacherId;
  const _HomeTab({required this.session, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.profile.path),
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                  'Today is ${Formatters.formatDate(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
_menuItem(
            context,
            'My Classes',
            'View and manage your assigned classes',
            Icons.class_outlined,
            Colors.blue,
            () => context.push(AppRoutes.teacherClasses.path),
          ),
          _menuItem(
            context,
            'Take Attendance',
            'Mark students present, absent or late',
            Icons.checklist_outlined,
            Colors.green,
            () => context.push(AppRoutes.teacherClasses.path),
          ),
          _menuItem(
            context,
            'Attendance History',
            'View previous attendance records',
            Icons.history,
            Colors.orange,
            () => context.push(AppRoutes.teacherClasses.path),
          ),
_menuItem(
            context,
            'Send Message',
            'Prepare parent messages via SMS',
            Icons.message_outlined,
            Colors.purple,
            () => context.push(AppRoutes.teacherSendMessage.path),
          ),
          _menuItem(
            context,
            'Homework Assignments',
            'Create assignments and review student work',
            Icons.assignment_outlined,
            Colors.teal,
            () => context.push(AppRoutes.teacherAssignments.path),
          ),
        ],
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

class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context) {
    return const MyClassesScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}