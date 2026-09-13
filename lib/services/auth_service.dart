import '../core/constants/app_constants.dart';
import '../core/utils/password_utils.dart';
import '../database/daos/school_dao.dart';
import '../database/daos/student_dao.dart';
import '../database/daos/teacher_dao.dart';

class AuthSession {
  int? _userId;
  String? _role;
  String? _userName;
  int? _schoolId;
  int? _divisionId;
  String? _rollNumber;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  String? get role => _role;
  String? get userName => _userName;
  int? get schoolId => _schoolId;
  int? get divisionId => _divisionId;
  String? get rollNumber => _rollNumber;
  bool get isAdmin => _role == AppConstants.roleAdmin;
  bool get isTeacher => _role == AppConstants.roleTeacher;
  bool get isStudent => _role == AppConstants.roleStudent;

  void loginAdmin({
    required int id,
    required String name,
    required int schoolId,
  }) {
    _userId = id;
    _role = AppConstants.roleAdmin;
    _userName = name;
    _schoolId = schoolId;
    _divisionId = null;
    _rollNumber = null;
    _isAuthenticated = true;
  }

  void loginTeacher({
    required int id,
    required String name,
    required int schoolId,
  }) {
    _userId = id;
    _role = AppConstants.roleTeacher;
    _userName = name;
    _schoolId = schoolId;
    _divisionId = null;
    _rollNumber = null;
    _isAuthenticated = true;
  }

  void loginStudent({
    required int id,
    required String name,
    required int schoolId,
    required int divisionId,
    required String rollNumber,
  }) {
    _userId = id;
    _role = AppConstants.roleStudent;
    _userName = name;
    _schoolId = schoolId;
    _divisionId = divisionId;
    _rollNumber = rollNumber;
    _isAuthenticated = true;
  }

  void logout() {
    _userId = null;
    _role = null;
    _userName = null;
    _schoolId = null;
    _divisionId = null;
    _rollNumber = null;
    _isAuthenticated = false;
  }
}

class AuthService {
  final SchoolDao _schoolDao;
  final TeacherDao _teacherDao;
  final StudentDao _studentDao;
  late final AuthSession _session;

  AuthService(this._schoolDao, this._teacherDao, this._studentDao) {
    _session = AuthSession();
  }

  AuthSession get session => _session;

  Future<bool> loginAdmin(String username, String password) async {
    final hash = PasswordUtils.hashPassword(password);
    final admin = await _schoolDao.loginAdmin(username, hash);
    if (admin != null) {
      _session.loginAdmin(
        id: admin.id,
        name: admin.name,
        schoolId: admin.schoolId,
      );
      return true;
    }
    return false;
  }

  Future<bool> loginTeacher(String username, String password) async {
    final hash = PasswordUtils.hashPassword(password);
    final teacher = await _teacherDao.loginTeacher(username, hash);
    if (teacher != null) {
      _session.loginTeacher(
        id: teacher.id,
        name: teacher.name,
        schoolId: teacher.schoolId,
      );
      return true;
    }
    return false;
  }

  Future<bool> loginStudent(String rollNumber, DateTime dob) async {
    final students =
        await _studentDao.findStudentsByRollAndDob(rollNumber, dob);
    if (students.isNotEmpty) {
      final student = students.first;
      _session.loginStudent(
        id: student.id,
        name: student.name,
        schoolId: student.schoolId,
        divisionId: student.divisionId,
        rollNumber: student.rollNumber,
      );
      return true;
    }
    return false;
  }

  void logout() {
    _session.logout();
  }
}