import '../database/app_database.dart';
import '../database/daos/school_dao.dart';
import '../database/daos/teacher_dao.dart';
import '../database/daos/class_dao.dart';
import '../database/daos/student_dao.dart';
import '../database/daos/attendance_dao.dart';
import '../database/daos/homework_dao.dart';
import '../database/daos/settings_dao.dart';

class DatabaseRepository {
  final AppDatabase _database;
  late final SchoolDao _schoolDao;
  late final TeacherDao _teacherDao;
  late final ClassDao _classDao;
  late final StudentDao _studentDao;
  late final AttendanceDao _attendanceDao;
  late final HomeworkDao _homeworkDao;
  late final SettingsDao _settingsDao;

  DatabaseRepository(this._database) {
    _schoolDao = SchoolDao(_database);
    _teacherDao = TeacherDao(_database);
    _classDao = ClassDao(_database);
    _studentDao = StudentDao(_database);
    _attendanceDao = AttendanceDao(_database);
    _homeworkDao = HomeworkDao(_database);
    _settingsDao = SettingsDao(_database);
  }

  AppDatabase get database => _database;
  SchoolDao get schoolDao => _schoolDao;
  TeacherDao get teacherDao => _teacherDao;
  ClassDao get classDao => _classDao;
  StudentDao get studentDao => _studentDao;
  AttendanceDao get attendanceDao => _attendanceDao;
  HomeworkDao get homeworkDao => _homeworkDao;
  SettingsDao get settingsDao => _settingsDao;

  Future<void> close() => _database.close();
}
