import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'teacher_dao.g.dart';

@DriftAccessor(tables: [Teachers, Classes, Divisions, TeacherClassAssignments])
class TeacherDao extends DatabaseAccessor<AppDatabase>
    with _$TeacherDaoMixin {
  TeacherDao(AppDatabase db) : super(db);

  Future<int> createTeacher(TeachersCompanion teacher) =>
      into(teachers).insert(teacher);

  Future<bool> updateTeacher(TeachersCompanion teacher) =>
      update(teachers).replace(teacher);

  Future<int> deleteTeacher(int id) =>
      (delete(teachers)..where((t) => t.id.equals(id))).go();

  Future<Teacher?> getTeacherById(int id) =>
      (select(teachers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Teacher>> getAllTeachers() => select(teachers).get();

  Stream<List<Teacher>> watchAllTeachers() => select(teachers).watch();

  Future<List<Teacher>> getActiveTeachers() =>
      (select(teachers)..where((t) => t.isActive.equals(true))).get();

  Future<Teacher?> loginTeacher(String username, String passwordHash) =>
      (select(teachers)..where((t) =>
              t.username.equals(username) &
              t.passwordHash.equals(passwordHash) &
              t.isActive.equals(true)))
          .getSingleOrNull();

  Future<void> assignTeacherToClass(TeacherClassAssignmentsCompanion assignment) =>
      into(teacherClassAssignments).insert(assignment);

  Future<void> removeTeacherClassAssignment(int id) =>
      (delete(teacherClassAssignments)..where((t) => t.id.equals(id))).go();

  Future<List<TeacherClassAssignment>> getAssignmentsForTeacher(int teacherId) =>
      (select(teacherClassAssignments)
            ..where((t) => t.teacherId.equals(teacherId)))
          .get();

  Stream<List<TeacherClassAssignment>> watchAssignmentsForTeacher(
          int teacherId) =>
      (select(teacherClassAssignments)
            ..where((t) => t.teacherId.equals(teacherId)))
          .watch();

  Future<List<TeacherClassAssignment>> getAllAssignments() =>
      select(teacherClassAssignments).get();

  Stream<List<TeacherClassAssignment>> watchAllAssignments() =>
      select(teacherClassAssignments).watch();

  Future<List<ClassesWithDivision>> getClassesForTeacher(int teacherId) async {
    final query = select(teacherClassAssignments).join([
      innerJoin(classes, classes.id.equalsExp(teacherClassAssignments.classId)),
      innerJoin(
          divisions, divisions.id.equalsExp(teacherClassAssignments.divisionId)),
    ])..where(teacherClassAssignments.teacherId.equals(teacherId));

    final results = await query.get();
    return results.map((row) {
      return ClassesWithDivision(
        assignmentId: row.readTable(teacherClassAssignments).id,
        classData: row.readTable(classes),
        divisionData: row.readTable(divisions),
      );
    }).toList();
  }
}

class ClassesWithDivision {
  final int assignmentId;
  final SchoolClass classData;
  final Division divisionData;

  ClassesWithDivision({
    required this.assignmentId,
    required this.classData,
    required this.divisionData,
  });
}
