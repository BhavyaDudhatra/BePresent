class AppConstants {
  AppConstants._();

  static const String appName = 'Be Present';
  static const String appTagline = 'School Attendance Management';
  static const String version = '2.0.0';

  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';

  // Settings keys
  static const String settingsSyncUrl = 'sync_url';
  static const String settingsSyncEnabled = 'sync_enabled';
  static const String settingsLastSyncAt = 'last_sync_at';
  static const String settingsPinHash = 'app_pin_hash';
}
