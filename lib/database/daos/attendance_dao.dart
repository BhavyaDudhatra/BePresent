import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [
  Attendances,
  Students,
  Divisions,
  Classes,
  Teachers,
  AttendanceStatuses,
  TeacherClassAssignments,
])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(AppDatabase db) : super(db);

  Future<void> saveAttendance({
    required int divisionId,
    required int teacherId,
    required DateTime date,
    required Map<int, int> studentStatusMap,
  }) async {
    await transaction(() async {
      for (final entry in studentStatusMap.entries) {
        final existingAttendance = await (select(attendances)
              ..where((t) =>
                  t.studentId.equals(entry.key) &
                  t.date.equals(date)))
            .getSingleOrNull();

        if (existingAttendance != null) {
          await (update(attendances)
                ..where((t) => t.id.equals(existingAttendance.id)))
              .write(AttendancesCompanion(
                statusId: Value(entry.value),
                teacherId: Value(teacherId),
              ));
        } else {
          await into(attendances).insert(AttendancesCompanion(
            studentId: Value(entry.key),
            statusId: Value(entry.value),
            date: Value(date),
            teacherId: Value(teacherId),
          ));
        }
      }
    });
  }

  Future<List<Attendance>> getAttendanceForDivisionAndDate(
      int divisionId, DateTime date) async {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
    ])
      ..where(
          students.divisionId.equals(divisionId) & attendances.date.equals(date));

    final results = await query.get();
    return results.map((row) => row.readTable(attendances)).toList();
  }

  Stream<List<AttendanceWithDetails>> watchAttendanceForDivisionAndDate(
      int divisionId, DateTime date) {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
      innerJoin(attendanceStatuses,
          attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(
          students.divisionId.equals(divisionId) & attendances.date.equals(date));

    return query.watch().map((rows) {
      return rows.map((row) {
        return AttendanceWithDetails(
          attendance: row.readTable(attendances),
          student: row.readTable(students),
          status: row.readTable(attendanceStatuses),
        );
      }).toList();
    });
  }

  Stream<List<AttendanceWithDetails>> allWithDetails(
      int assignmentId, DateTime date) async* {
    final assignment = await (select(teacherClassAssignments)
          ..where((t) => t.id.equals(assignmentId)))
        .getSingle();
    yield* watchAttendanceForDivisionAndDate(assignment.divisionId, date);
  }

  Future<List<AttendanceWithDetails>> getAttendanceForDivisionAndDateList(
      int divisionId, DateTime date) async {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
      innerJoin(attendanceStatuses,
          attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(
          students.divisionId.equals(divisionId) & attendances.date.equals(date));

    final results = await query.get();
    return results.map((row) {
      return AttendanceWithDetails(
        attendance: row.readTable(attendances),
        student: row.readTable(students),
        status: row.readTable(attendanceStatuses),
      );
    }).toList();
  }

  Future<List<AttendanceWithDetails>> getAttendanceForStudent(
      int studentId) async {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
      innerJoin(attendanceStatuses,
          attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(attendances.studentId.equals(studentId))
      ..orderBy([OrderingTerm.desc(attendances.date)]);

    final results = await query.get();
    return results.map((row) {
      return AttendanceWithDetails(
        attendance: row.readTable(attendances),
        student: row.readTable(students),
        status: row.readTable(attendanceStatuses),
      );
    }).toList();
  }

  Future<List<AttendanceWithDetails>> getAllAttendanceWithDetails() async {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
      innerJoin(attendanceStatuses,
          attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])..orderBy([OrderingTerm.desc(attendances.date)]);

    final results = await query.get();
    return results.map((row) {
      return AttendanceWithDetails(
        attendance: row.readTable(attendances),
        student: row.readTable(students),
        status: row.readTable(attendanceStatuses),
      );
    }).toList();
  }

  Future<List<AttendanceWithDetails>> getAllAttendanceForDate(DateTime date) async {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
      innerJoin(attendanceStatuses,
          attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(attendances.date.equals(date))
      ..orderBy([OrderingTerm.asc(attendances.id)]);

    final results = await query.get();
    return results.map((row) {
      return AttendanceWithDetails(
        attendance: row.readTable(attendances),
        student: row.readTable(students),
        status: row.readTable(attendanceStatuses),
      );
    }).toList();
  }

  Stream<List<AttendanceWithDetails>> watchAttendanceForStudent(
      int studentId) {
    final query = select(attendances).join([
      innerJoin(students, students.id.equalsExp(attendances.studentId)),
      innerJoin(attendanceStatuses,
          attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(attendances.studentId.equals(studentId))
      ..orderBy([OrderingTerm.desc(attendances.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return AttendanceWithDetails(
          attendance: row.readTable(attendances),
          student: row.readTable(students),
          status: row.readTable(attendanceStatuses),
        );
      }).toList();
    });
  }

  Future<AttendanceSummary> getAttendanceSummary(
      int studentId, DateTime startDate, DateTime endDate) async {
    final records = await (select(attendances)
          ..where((t) =>
              t.studentId.equals(studentId) &
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate)))
        .get();

    int present = 0, absent = 0, late = 0;

    for (final record in records) {
      final status =
          await (select(attendanceStatuses)
                ..where((t) => t.id.equals(record.statusId)))
              .getSingleOrNull();
      if (status != null) {
        switch (status.name) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
        }
      }
    }

    final total = present + absent + late;
    final percentage = total > 0 ? (present / total) * 100 : 0.0;

    return AttendanceSummary(
      totalDays: total,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      percentage: percentage,
    );
  }

  Future<AttendanceSummary> getDivisionAttendanceSummary(
      int divisionId, DateTime date) async {
    final records = await getAttendanceForDivisionAndDate(divisionId, date);

    int present = 0, absent = 0, late = 0;

    for (final record in records) {
      final status =
          await (select(attendanceStatuses)
                ..where((t) => t.id.equals(record.statusId)))
              .getSingleOrNull();
      if (status != null) {
        switch (status.name) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
        }
      }
    }

    final total = present + absent + late;
    final percentage = total > 0 ? (present / total) * 100 : 0.0;

    return AttendanceSummary(
      totalDays: total,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      percentage: percentage,
    );
  }

  Future<List<AttendanceStatu>> getAllStatuses() =>
      select(attendanceStatuses).get();

  Future<AttendanceStatu?> getStatusByName(String name) =>
      (select(attendanceStatuses)..where((t) => t.name.equals(name)))
          .getSingleOrNull();

  Future<AttendanceSummary> getSchoolWideSummary(DateTime date) async {
    final query = select(attendances).join([
      innerJoin(
          attendanceStatuses, attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(attendances.date.equals(date));

    final rows = await query.get();
    return _summarize(rows.map((r) => r.readTable(attendanceStatuses).name));
  }

  Future<List<({DateTime date, AttendanceSummary summary})>>
      getSchoolWideWeeklySummaries(DateTime endDate) async {
    final from = DateTime(endDate.year, endDate.month, endDate.day - 6);
    final to = DateTime(endDate.year, endDate.month, endDate.day);
    final query = select(attendances).join([
      innerJoin(
          attendanceStatuses, attendanceStatuses.id.equalsExp(attendances.statusId)),
    ])
      ..where(attendances.date.isBiggerOrEqualValue(from) &
          attendances.date.isSmallerOrEqualValue(to));

    final rows = await query.get();
    final byDate = <DateTime, List<String>>{};
    for (final row in rows) {
      final date = DateTime(
          row.readTable(attendances).date.year,
          row.readTable(attendances).date.month,
          row.readTable(attendances).date.day);
      byDate.putIfAbsent(date, () => []).add(row.readTable(attendanceStatuses).name);
    }

    return [
      for (var i = 6; i >= 0; i--)
        () {
          final d = DateTime(endDate.year, endDate.month, endDate.day - i);
          return (date: d, summary: _summarize(byDate[d] ?? const []));
        }(),
    ];
  }

  AttendanceSummary _summarize(Iterable<String> statusNames) {
    int present = 0, absent = 0, late = 0;
    for (final name in statusNames) {
      switch (name) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
      }
    }
    final total = present + absent + late;
    final percentage = total > 0 ? (present / total) * 100 : 0.0;
    return AttendanceSummary(
      totalDays: total,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      percentage: percentage,
    );
  }
}

class AttendanceWithDetails {
  final Attendance attendance;
  final Student student;
  final AttendanceStatu status;

  AttendanceWithDetails({
    required this.attendance,
    required this.student,
    required this.status,
  });
}

class AttendanceSummary {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double percentage;

  AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.percentage,
  });
}
