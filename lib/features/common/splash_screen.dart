import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

Future<void> _initialize() async {
    await ref.read(seedInitializedProvider.future);
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    final pinService = ref.read(pinServiceProvider);
    final pinSet = await pinService.isPinSet();
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (auth.isAuthenticated) {
        if (pinSet) {
          context.go(AppRoutes.pinLock.path);
        } else if (auth.isAdmin) {
          context.go(AppRoutes.adminDashboard.path);
        } else if (auth.isTeacher) {
          context.go(AppRoutes.teacherDashboard.path);
        } else {
          context.go(AppRoutes.studentDashboard.path);
        }
      } else {
        if (pinSet) {
          context.go(AppRoutes.pinLock.path);
        } else {
          context.go(AppRoutes.login.path);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Be Present',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'School Attendance Management',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}