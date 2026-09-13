import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/add_edit_student_screen.dart';
import '../features/admin/add_edit_teacher_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/assign_teachers_screen.dart';
import '../features/admin/attendance_overview_screen.dart';
import '../features/admin/manage_classes_screen.dart';
import '../features/admin/manage_divisions_screen.dart';
import '../features/admin/manage_students_screen.dart';
import '../features/admin/manage_teachers_screen.dart';
import '../features/admin/school_settings_screen.dart';
import '../features/admin/student_attendance_report_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/common/backup_restore_screen.dart';
import '../features/common/export_screen.dart';
import '../features/common/pin_screens.dart';
import '../features/common/profile_screen.dart';
import '../features/common/splash_screen.dart';
import '../features/common/sync_settings_screen.dart';
import '../features/student/student_assignments_screen.dart';
import '../features/student/student_assignment_detail_screen.dart';
import '../features/student/student_attendance_report_screen.dart'
    as student_report;
import '../features/student/student_dashboard.dart';
import '../features/teacher/attendance_history_screen.dart';
import '../features/teacher/create_assignment_screen.dart';
import '../features/teacher/my_classes_screen.dart';
import '../features/teacher/student_attendance_report_screen.dart' as teacher_report;
import '../features/teacher/student_list_screen.dart';
import '../features/teacher/take_attendance_screen.dart';
import '../features/teacher/teacher_assignments_screen.dart';
import '../features/teacher/teacher_assignment_detail_screen.dart';
import '../features/teacher/teacher_dashboard.dart';
import '../features/teacher/send_message_screen.dart';
import '../providers/providers.dart';

enum AppRoutes {
  splash('/'),
  pinLock('/pin'),
  login('/login'),
  adminDashboard('/admin'),
  adminClasses('/admin/classes'),
  adminDivisions('/admin/divisions'),
  adminStudents('/admin/students'),
  adminAddStudent('/admin/students/add'),
  adminEditStudent('/admin/students/edit/:studentId'),
  adminTeachers('/admin/teachers'),
  adminAddTeacher('/admin/teachers/add'),
  adminEditTeacher('/admin/teachers/edit/:teacherId'),
  adminAssignTeachers('/admin/assign-teachers'),
  adminAttendanceOverview('/admin/attendance'),
  adminStudentReport('/admin/attendance/student-report'),
  adminSendMessage('/admin/send-message'),
  adminSchoolSettings('/admin/settings'),
  teacherDashboard('/teacher'),
  teacherClasses('/teacher/classes'),
  teacherAttendance('/teacher/attendance/:assignmentId'),
  teacherHistory('/teacher/history/:assignmentId'),
  teacherStudents('/teacher/students/:assignmentId'),
  teacherStudentReport('/teacher/student-report/:studentId'),
  teacherSendMessage('/teacher/send-message'),
  teacherAssignments('/teacher/assignments'),
  teacherNewAssignment('/teacher/assignments/new'),
  teacherAssignmentDetail('/teacher/assignments/:assignmentId'),
  studentDashboard('/student'),
  studentAttendance('/student/attendance'),
  studentAssignments('/student/assignments'),
  studentAssignmentDetail('/student/assignments/:assignmentId'),
  syncSettings('/settings/sync'),
  backupRestore('/settings/backup'),
  export('/settings/export'),
  profile('/profile');

  final String path;
  const AppRoutes(this.path);

  String build(Map<String, String> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceFirst(':$key', value);
    });
    return result;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash.path,
    routes: [
      GoRoute(
        path: AppRoutes.splash.path,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard.path,
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.adminClasses.path,
        builder: (context, state) => const ManageClassesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDivisions.path,
        builder: (context, state) => const ManageDivisionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudents.path,
        builder: (context, state) => const ManageStudentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAddStudent.path,
        builder: (context, state) => const AddEditStudentScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEditStudent.path,
        builder: (context, state) => AddEditStudentScreen(
          studentId: int.tryParse(state.pathParameters['studentId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminTeachers.path,
        builder: (context, state) => const ManageTeachersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAddTeacher.path,
        builder: (context, state) => const AddEditTeacherScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEditTeacher.path,
        builder: (context, state) => AddEditTeacherScreen(
          teacherId: int.tryParse(state.pathParameters['teacherId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAssignTeachers.path,
        builder: (context, state) => const AssignTeachersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAttendanceOverview.path,
        builder: (context, state) => const AttendanceOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudentReport.path,
        builder: (context, state) =>
            const StudentAttendanceReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSendMessage.path,
        builder: (context, state) => const SendMessageScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSchoolSettings.path,
        builder: (context, state) => const SchoolSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherDashboard.path,
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: AppRoutes.teacherClasses.path,
        builder: (context, state) => const MyClassesScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherAttendance.path,
        builder: (context, state) => TakeAttendanceScreen(
          assignmentId:
              int.tryParse(state.pathParameters['assignmentId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherHistory.path,
        builder: (context, state) => AttendanceHistoryScreen(
          assignmentId:
              int.tryParse(state.pathParameters['assignmentId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherStudents.path,
        builder: (context, state) => StudentListScreen(
          assignmentId:
              int.tryParse(state.pathParameters['assignmentId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherStudentReport.path,
        builder: (context, state) => teacher_report.StudentAttendanceReportScreen(
          studentId:
              int.tryParse(state.pathParameters['studentId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.teacherSendMessage.path,
        builder: (context, state) => const SendMessageScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherAssignments.path,
        builder: (context, state) => const TeacherAssignmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherNewAssignment.path,
        builder: (context, state) => const CreateAssignmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherAssignmentDetail.path,
        builder: (context, state) => TeacherAssignmentDetailScreen(
          assignmentId:
              int.tryParse(state.pathParameters['assignmentId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.studentDashboard.path,
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: AppRoutes.studentAttendance.path,
        builder: (context, state) => const student_report.StudentAttendanceReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentAssignments.path,
        builder: (context, state) => const StudentAssignmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentAssignmentDetail.path,
        builder: (context, state) => StudentAssignmentDetailScreen(
          assignmentId:
              int.tryParse(state.pathParameters['assignmentId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.syncSettings.path,
        builder: (context, state) => const SyncSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.backupRestore.path,
        builder: (context, state) => const BackupRestoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.export.path,
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile.path,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinLock.path,
        builder: (context, state) => const PinLockScreen(),
      ),
    ],
    redirect: (context, state) {
      final authSession = ref.read(authStateProvider);
      final isAuthRoute = state.matchedLocation == AppRoutes.login.path ||
          state.matchedLocation == AppRoutes.splash.path ||
          state.matchedLocation == AppRoutes.pinLock.path;

      if (state.matchedLocation == AppRoutes.splash.path) {
        return null;
      }

      if (!authSession.isAuthenticated && !isAuthRoute) {
        return AppRoutes.login.path;
      }

      if (authSession.isAuthenticated &&
          (state.matchedLocation == AppRoutes.login.path ||
              state.matchedLocation == AppRoutes.splash.path)) {
        if (authSession.isAdmin) return AppRoutes.adminDashboard.path;
        if (authSession.isTeacher) return AppRoutes.teacherDashboard.path;
        return AppRoutes.studentDashboard.path;
      }

      final isAdminRoute =
          state.matchedLocation.startsWith('/admin/') ||
              state.matchedLocation == AppRoutes.adminDashboard.path;
      if (isAdminRoute && !authSession.isAdmin) {
        if (authSession.isTeacher) return AppRoutes.teacherDashboard.path;
        return AppRoutes.studentDashboard.path;
      }

      final isTeacherRoute =
          state.matchedLocation.startsWith('/teacher/') ||
              state.matchedLocation == AppRoutes.teacherDashboard.path;
      if (isTeacherRoute && !authSession.isTeacher) {
        if (authSession.isAdmin) return AppRoutes.adminDashboard.path;
        return AppRoutes.studentDashboard.path;
      }

      final isStudentRoute =
          state.matchedLocation.startsWith('/student/') ||
              state.matchedLocation == AppRoutes.studentDashboard.path;
      if (isStudentRoute && !authSession.isStudent) {
        if (authSession.isAdmin) return AppRoutes.adminDashboard.path;
        return AppRoutes.teacherDashboard.path;
      }

      return null;
    },
  );
});