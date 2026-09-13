import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'homework_dao.g.dart';

@DriftAccessor(tables: [
  HomeworkAssignments,
  HomeworkSubmissions,
  Students,
  Classes,
  Divisions,
  Teachers,
  TeacherClassAssignments,
])
class HomeworkDao extends DatabaseAccessor<AppDatabase> with _$HomeworkDaoMixin {
  HomeworkDao(super.db);

  Future<int> createAssignment(HomeworkAssignmentsCompanion assignment) =>
      into(homeworkAssignments).insert(assignment);

  Future<bool> updateAssignment(HomeworkAssignmentsCompanion assignment) =>
      update(homeworkAssignments).replace(assignment);

  Future<int> deleteAssignment(int id) =>
      (delete(homeworkAssignments)..where((t) => t.id.equals(id))).go();

  Future<HomeworkAssignment?> getAssignmentById(int id) =>
      (select(homeworkAssignments)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<HomeworkAssignmentDetail>> getAllAssignmentsWithDetails() async {
    final query = select(homeworkAssignments).join([
      innerJoin(classes, classes.id.equalsExp(homeworkAssignments.classId)),
      innerJoin(
          divisions, divisions.id.equalsExp(homeworkAssignments.divisionId)),
      innerJoin(
          teachers, teachers.id.equalsExp(homeworkAssignments.teacherId)),
    ])..orderBy([OrderingTerm.desc(homeworkAssignments.dueDate)]);
    final rows = await query.get();
    return rows.map((row) {
      return HomeworkAssignmentDetail(
        assignment: row.readTable(homeworkAssignments),
        classData: row.readTable(classes),
        division: row.readTable(divisions),
        teacher: row.readTable(teachers),
      );
    }).toList();
  }

  Future<List<HomeworkSubmissionSync>> getAllSubmissionsWithDetails() async {
    final query = select(homeworkSubmissions).join([
      innerJoin(
          students, students.id.equalsExp(homeworkSubmissions.studentId)),
      innerJoin(homeworkAssignments,
          homeworkAssignments.id.equalsExp(homeworkSubmissions.assignmentId)),
    ])..orderBy([OrderingTerm.desc(homeworkSubmissions.submittedAt)]);
    final rows = await query.get();
    return rows.map((row) {
      return HomeworkSubmissionSync(
        submission: row.readTable(homeworkSubmissions),
        student: row.readTable(students),
        assignment: row.readTable(homeworkAssignments),
      );
    }).toList();
  }

  Future<HomeworkAssignmentDetail?> getAssignmentWithDetails(int id) async {
    final query = select(homeworkAssignments).join([
      innerJoin(classes, classes.id.equalsExp(homeworkAssignments.classId)),
      innerJoin(
          divisions, divisions.id.equalsExp(homeworkAssignments.divisionId)),
      innerJoin(
          teachers, teachers.id.equalsExp(homeworkAssignments.teacherId)),
    ])..where(homeworkAssignments.id.equals(id));
    final rows = await query.get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return HomeworkAssignmentDetail(
      assignment: row.readTable(homeworkAssignments),
      classData: row.readTable(classes),
      division: row.readTable(divisions),
      teacher: row.readTable(teachers),
    );
  }

  Stream<List<HomeworkAssignmentDetail>> watchAssignmentsForTeacher(
      int teacherId) {
    final query = select(homeworkAssignments).join([
      innerJoin(classes, classes.id.equalsExp(homeworkAssignments.classId)),
      innerJoin(
          divisions, divisions.id.equalsExp(homeworkAssignments.divisionId)),
      innerJoin(
          teachers, teachers.id.equalsExp(homeworkAssignments.teacherId)),
    ])
      ..where(homeworkAssignments.teacherId.equals(teacherId))
      ..orderBy([OrderingTerm.desc(homeworkAssignments.dueDate)]);
    return query.watch().map((rows) {
      return rows.map((row) {
        return HomeworkAssignmentDetail(
          assignment: row.readTable(homeworkAssignments),
          classData: row.readTable(classes),
          division: row.readTable(divisions),
          teacher: row.readTable(teachers),
        );
      }).toList();
    });
  }

  Stream<List<HomeworkAssignmentDetail>> watchAssignmentsForDivision(
      int divisionId) {
    final query = select(homeworkAssignments).join([
      innerJoin(classes, classes.id.equalsExp(homeworkAssignments.classId)),
      innerJoin(
          divisions, divisions.id.equalsExp(homeworkAssignments.divisionId)),
      innerJoin(
          teachers, teachers.id.equalsExp(homeworkAssignments.teacherId)),
    ])
      ..where(homeworkAssignments.divisionId.equals(divisionId))
      ..orderBy([OrderingTerm.desc(homeworkAssignments.dueDate)]);
    return query.watch().map((rows) {
      return rows.map((row) {
        return HomeworkAssignmentDetail(
          assignment: row.readTable(homeworkAssignments),
          classData: row.readTable(classes),
          division: row.readTable(divisions),
          teacher: row.readTable(teachers),
        );
      }).toList();
    });
  }

  Stream<List<HomeworkSubmissionWithStudent>>
      watchSubmissionsForAssignment(int assignmentId) {
    final query = select(homeworkSubmissions).join([
      innerJoin(
          students, students.id.equalsExp(homeworkSubmissions.studentId)),
    ])
      ..where(homeworkSubmissions.assignmentId.equals(assignmentId))
      ..orderBy([OrderingTerm.desc(homeworkSubmissions.submittedAt)]);
    return query.watch().map((rows) {
      return rows.map((row) {
        return HomeworkSubmissionWithStudent(
          submission: row.readTable(homeworkSubmissions),
          student: row.readTable(students),
        );
      }).toList();
    });
  }

  Stream<List<HomeworkSubmission>> watchSubmissionsForStudent(int studentId) {
    return (select(homeworkSubmissions)
          ..where((t) => t.studentId.equals(studentId)))
        .watch();
  }

  Future<HomeworkSubmission?> getMySubmission(
      int assignmentId, int studentId) async {
    return (select(homeworkSubmissions)
          ..where((t) =>
              t.assignmentId.equals(assignmentId) &
              t.studentId.equals(studentId)))
        .getSingleOrNull();
  }

  Stream<HomeworkSubmission?> watchMySubmission(
      int assignmentId, int studentId) {
    return (select(homeworkSubmissions)
          ..where((t) =>
              t.assignmentId.equals(assignmentId) &
              t.studentId.equals(studentId)))
        .watchSingleOrNull();
  }

  Future<void> upsertSubmission({
    required int assignmentId,
    required int studentId,
    String? text,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    final existing = await getMySubmission(assignmentId, studentId);
    final now = DateTime.now();
    if (existing == null) {
      await into(homeworkSubmissions).insert(HomeworkSubmissionsCompanion.insert(
        assignmentId: assignmentId,
        studentId: studentId,
        submissionText: Value(text),
        attachmentPath: Value(attachmentPath),
        attachmentName: Value(attachmentName),
        submittedAt: Value(now),
      ));
    } else {
      await (update(homeworkSubmissions)
            ..where((t) =>
                t.assignmentId.equals(assignmentId) &
                t.studentId.equals(studentId)))
          .write(HomeworkSubmissionsCompanion(
        submissionText: Value(text),
        attachmentPath: Value(attachmentPath),
        attachmentName: Value(attachmentName),
        submittedAt: Value(now),
        updatedAt: Value(now),
      ));
    }
  }

  Future<void> setFeedback({
    required int assignmentId,
    required int studentId,
    required String feedback,
  }) async {
    await (update(homeworkSubmissions)
          ..where((t) =>
              t.assignmentId.equals(assignmentId) &
              t.studentId.equals(studentId)))
        .write(HomeworkSubmissionsCompanion(
      feedback: Value(feedback),
      feedbackAt: Value(DateTime.now()),
    ));
  }
}

class HomeworkAssignmentDetail {
  final HomeworkAssignment assignment;
  final SchoolClass classData;
  final Division division;
  final Teacher teacher;

  HomeworkAssignmentDetail({
    required this.assignment,
    required this.classData,
    required this.division,
    required this.teacher,
  });
}

class HomeworkSubmissionWithStudent {
  final HomeworkSubmission submission;
  final Student student;

  HomeworkSubmissionWithStudent({
    required this.submission,
    required this.student,
  });
}

class HomeworkSubmissionSync {
  final HomeworkSubmission submission;
  final Student student;
  final HomeworkAssignment assignment;

  HomeworkSubmissionSync({
    required this.submission,
    required this.student,
    required this.assignment,
  });
}