import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [
  Students,
  Divisions,
  Classes,
  ParentGuardians,
])
class StudentDao extends DatabaseAccessor<AppDatabase>
    with _$StudentDaoMixin {
  StudentDao(AppDatabase db) : super(db);

  Future<int> createStudent(StudentsCompanion student) =>
      into(students).insert(student);

  Future<bool> updateStudent(StudentsCompanion student) =>
      update(students).replace(student);

  Future<int> deleteStudent(int id) =>
      (delete(students)..where((t) => t.id.equals(id))).go();

  Future<Student?> getStudentById(int id) =>
      (select(students)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Student>> getStudentsByDivision(int divisionId) =>
      (select(students)
            ..where((t) =>
                t.divisionId.equals(divisionId) &
                t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.rollNumber)]))
          .get();

  Stream<List<Student>> watchStudentsByDivision(int divisionId) =>
      (select(students)
            ..where((t) =>
                t.divisionId.equals(divisionId) &
                t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.rollNumber)]))
          .watch();

  Future<List<Student>> getAllStudents() =>
      (select(students)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Stream<List<Student>> watchAllStudents() =>
      (select(students)..where((t) => t.isActive.equals(true))).watch();

  Future<List<Student>> findStudentsByRollAndDob(
      String rollNumber, DateTime dob) async {
    final all = await (select(students)
          ..where((t) =>
              t.rollNumber.equals(rollNumber) & t.isActive.equals(true)))
        .get();
    final day = DateTime(dob.year, dob.month, dob.day);
    return all.where((s) {
      final d = s.dateOfBirth;
      if (d == null) return false;
      final sd = DateTime(d.year, d.month, d.day);
      return sd == day;
    }).toList();
  }

  Future<int> addParentGuardian(ParentGuardiansCompanion guardian) =>
      into(parentGuardians).insert(guardian);

  Future<bool> updateParentGuardian(ParentGuardiansCompanion guardian) =>
      update(parentGuardians).replace(guardian);

  Future<int> deleteParentGuardian(int id) =>
      (delete(parentGuardians)..where((t) => t.id.equals(id))).go();

  Future<List<ParentGuardian>> getGuardiansForStudent(int studentId) =>
      (select(parentGuardians)
            ..where((t) => t.studentId.equals(studentId)))
          .get();

  Stream<List<ParentGuardian>> watchGuardiansForStudent(int studentId) =>
      (select(parentGuardians)
            ..where((t) => t.studentId.equals(studentId)))
          .watch();

  Future<StudentWithDetails?> getStudentWithDetails(int studentId) async {
    final student =
        await (select(students)..where((t) => t.id.equals(studentId)))
            .getSingleOrNull();
    if (student == null) return null;

    final division =
        await (select(divisions)..where((t) => t.id.equals(student.divisionId)))
            .getSingleOrNull();

    final classData = division != null
        ? await (select(classes)..where((t) => t.id.equals(division.classId)))
            .getSingleOrNull()
        : null;

    final guardians = await getGuardiansForStudent(studentId);

    return StudentWithDetails(
      student: student,
      division: division,
      classData: classData,
      guardians: guardians,
    );
  }

  Future<List<StudentWithDetails>> getStudentsWithDetailsByDivision(
      int divisionId) async {
    final studentList = await getStudentsByDivision(divisionId);
    final details = <StudentWithDetails>[];
    for (final student in studentList) {
      final detail = await getStudentWithDetails(student.id);
      if (detail != null) details.add(detail);
    }
    return details;
  }
}

class StudentWithDetails {
  final Student student;
  final Division? division;
  final SchoolClass? classData;
  final List<ParentGuardian> guardians;

  StudentWithDetails({
    required this.student,
    this.division,
    this.classData,
    required this.guardians,
  });
}
