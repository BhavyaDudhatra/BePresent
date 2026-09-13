import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tables.dart';

part 'app_database.g.dart';

typedef SchoolClass = ClassesData;
typedef AttendanceStatu = AttendanceStatuse;

@DriftDatabase(tables: [
  Schools,
  Admins,
  Teachers,
  Classes,
  Divisions,
  Students,
  ParentGuardians,
  AttendanceStatuses,
  Attendances,
  TeacherClassAssignments,
  HomeworkAssignments,
  HomeworkSubmissions,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(homeworkAssignments);
            await m.createTable(homeworkSubmissions);
            await m.createTable(settings);
          }
        },
      );

  Future<void> _seedDefaultData() async {
    await into(attendanceStatuses).insert(
      AttendanceStatusesCompanion.insert(
        name: 'present',
        label: 'Present',
        color: '#4CAF50',
      ),
    );
    await into(attendanceStatuses).insert(
      AttendanceStatusesCompanion.insert(
        name: 'absent',
        label: 'Absent',
        color: '#F44336',
      ),
    );
    await into(attendanceStatuses).insert(
      AttendanceStatusesCompanion.insert(
        name: 'late',
        label: 'Late',
        color: '#FF9800',
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'be_present.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
