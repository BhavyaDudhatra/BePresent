import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/attendance_dao.dart';
import '../database/daos/class_dao.dart';
import '../database/daos/homework_dao.dart';
import '../database/daos/school_dao.dart';
import '../database/daos/settings_dao.dart';
import '../database/daos/student_dao.dart';
import '../database/daos/teacher_dao.dart';
import '../repositories/database_repository.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/export_service.dart';
import '../services/pin_service.dart';
import '../services/seed_data_service.dart';
import '../services/sms_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close().catchError((_) {});
  });
  return db;
});

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return DatabaseRepository(ref.watch(databaseProvider));
});

final schoolDaoProvider = Provider<SchoolDao>(
  (ref) => ref.watch(databaseRepositoryProvider).schoolDao,
);

final teacherDaoProvider = Provider<TeacherDao>(
  (ref) => ref.watch(databaseRepositoryProvider).teacherDao,
);

final classDaoProvider = Provider<ClassDao>(
  (ref) => ref.watch(databaseRepositoryProvider).classDao,
);

final studentDaoProvider = Provider<StudentDao>(
  (ref) => ref.watch(databaseRepositoryProvider).studentDao,
);

final attendanceDaoProvider = Provider<AttendanceDao>(
  (ref) => ref.watch(databaseRepositoryProvider).attendanceDao,
);

final homeworkDaoProvider = Provider<HomeworkDao>(
  (ref) => ref.watch(databaseRepositoryProvider).homeworkDao,
);

final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => ref.watch(databaseRepositoryProvider).settingsDao,
);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(schoolDaoProvider),
    ref.watch(teacherDaoProvider),
    ref.watch(studentDaoProvider),
  );
});

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(
    ref.watch(settingsDaoProvider),
    ref.watch(attendanceDaoProvider),
    ref.watch(homeworkDaoProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    () => ref.invalidate(databaseProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    attendanceDao: ref.watch(attendanceDaoProvider),
    homeworkDao: ref.watch(homeworkDaoProvider),
    studentDao: ref.watch(studentDaoProvider),
  );
});

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.watch(settingsDaoProvider));
});

final seedDataServiceProvider = Provider<SeedDataService>((ref) {
  return SeedDataService(ref.watch(databaseProvider));
});

final seedInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(seedDataServiceProvider);
  await service.seedIfEmpty();
  return true;
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthSession>(
    (ref) {
  return AuthStateNotifier(ref.watch(authServiceProvider));
});

class AuthStateNotifier extends StateNotifier<AuthSession> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(_authService.session);

  Future<bool> loginAdmin(String username, String password) async {
    final success = await _authService.loginAdmin(username, password);
    if (success) {
      state = _authService.session;
    }
    return success;
  }

  Future<bool> loginTeacher(String username, String password) async {
    final success = await _authService.loginTeacher(username, password);
    if (success) {
      state = _authService.session;
    }
    return success;
  }

  Future<bool> loginStudent(String rollNumber, DateTime dob) async {
    final success = await _authService.loginStudent(rollNumber, dob);
    if (success) {
      state = _authService.session;
    }
    return success;
  }

  void logout() {
    _authService.logout();
    state = _authService.session;
  }
}

// ---------------------------------------------------------------------------
// Reactive stream providers
// ---------------------------------------------------------------------------

final allClassesStreamProvider =
    StreamProvider.autoDispose<List<SchoolClass>>((ref) {
  return ref.watch(classDaoProvider).watchAllClasses();
});

final divisionsForClassProvider =
    StreamProvider.autoDispose.family<List<Division>, int>((ref, classId) {
  return ref.watch(classDaoProvider).watchDivisionsForClass(classId);
});

final classDetailProvider = StreamProvider.autoDispose.family<ClassDetail,
    ({int classId, int divisionId})>((ref, args) {
  return ref
      .watch(classDaoProvider)
      .watchClassDetail(args.classId, args.divisionId);
});

final allTeachersStreamProvider =
    StreamProvider.autoDispose<List<Teacher>>((ref) {
  return ref.watch(teacherDaoProvider).watchAllTeachers();
});

final allAssignmentsStreamProvider =
    StreamProvider.autoDispose<List<TeacherClassAssignment>>((ref) {
  return ref.watch(teacherDaoProvider).watchAllAssignments();
});

final assignmentsForTeacherProvider =
    StreamProvider.autoDispose.family<List<TeacherClassAssignment>, int>(
        (ref, teacherId) {
  return ref.watch(teacherDaoProvider).watchAssignmentsForTeacher(teacherId);
});

final studentsByDivisionProvider =
    StreamProvider.autoDispose.family<List<Student>, int>((ref, divisionId) {
  return ref
      .watch(studentDaoProvider)
      .watchStudentsByDivision(divisionId);
});

final attendanceForDivisionAndDateProvider =
    StreamProvider.autoDispose.family<List<AttendanceWithDetails>,
        ({int divisionId, DateTime date})>((ref, args) {
  return ref
      .watch(attendanceDaoProvider)
      .watchAttendanceForDivisionAndDate(args.divisionId, args.date);
});

final allAttendanceWithDetailsProvider =
    StreamProvider.autoDispose.family<List<AttendanceWithDetails>,
        ({int assignmentId, DateTime date})>((ref, args) {
  return ref
      .watch(attendanceDaoProvider)
      .allWithDetails(args.assignmentId, args.date);
});

final allAttendanceForDateProvider =
    FutureProvider.autoDispose.family<List<AttendanceWithDetails>, DateTime>(
        (ref, date) {
  return ref.watch(attendanceDaoProvider).getAllAttendanceForDate(date);
});

// ---------------------------------------------------------------------------
// Homework / assignments providers
// ---------------------------------------------------------------------------

final teacherAssignmentsProvider =
    StreamProvider.autoDispose.family<List<HomeworkAssignmentDetail>, int>(
        (ref, teacherId) {
  return ref.watch(homeworkDaoProvider).watchAssignmentsForTeacher(teacherId);
});

final assignmentsForDivisionProvider =
    StreamProvider.autoDispose.family<List<HomeworkAssignmentDetail>, int>(
        (ref, divisionId) {
  return ref.watch(homeworkDaoProvider).watchAssignmentsForDivision(divisionId);
});

final submissionsForAssignmentProvider =
    StreamProvider.autoDispose.family<List<HomeworkSubmissionWithStudent>, int>(
        (ref, assignmentId) {
  return ref
      .watch(homeworkDaoProvider)
      .watchSubmissionsForAssignment(assignmentId);
});

final mySubmissionsProvider =
    StreamProvider.autoDispose.family<List<HomeworkSubmission>, int>(
        (ref, studentId) {
  return ref.watch(homeworkDaoProvider).watchSubmissionsForStudent(studentId);
});