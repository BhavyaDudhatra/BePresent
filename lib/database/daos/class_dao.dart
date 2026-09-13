import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'class_dao.g.dart';

@DriftAccessor(tables: [Classes, Divisions])
class ClassDao extends DatabaseAccessor<AppDatabase> with _$ClassDaoMixin {
  ClassDao(AppDatabase db) : super(db);

  Future<int> createClass(ClassesCompanion cls) => into(classes).insert(cls);

  Future<bool> updateClass(ClassesCompanion cls) =>
      update(classes).replace(cls);

  Future<int> deleteClass(int id) =>
      (delete(classes)..where((t) => t.id.equals(id))).go();

  Future<SchoolClass?> getClassById(int id) =>
      (select(classes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SchoolClass>> getAllClasses() => select(classes).get();

  Stream<List<SchoolClass>> watchAllClasses() => select(classes).watch();

  Future<List<SchoolClass>> getClassesBySchool(int schoolId) =>
      (select(classes)..where((t) => t.schoolId.equals(schoolId))).get();

  Future<int> createDivision(DivisionsCompanion division) =>
      into(divisions).insert(division);

  Future<bool> updateDivision(DivisionsCompanion division) =>
      update(divisions).replace(division);

  Future<int> deleteDivision(int id) =>
      (delete(divisions)..where((t) => t.id.equals(id))).go();

  Future<Division?> getDivisionById(int id) =>
      (select(divisions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Division>> getDivisionsForClass(int classId) =>
      (select(divisions)..where((t) => t.classId.equals(classId))).get();

  Stream<List<Division>> watchDivisionsForClass(int classId) =>
      (select(divisions)..where((t) => t.classId.equals(classId))).watch();

  Future<List<DivisionWithClass>> getAllDivisionsWithClass() async {
    final query = select(divisions).join([
      innerJoin(classes, classes.id.equalsExp(divisions.classId)),
    ]);

    final results = await query.get();
    return results.map((row) {
      return DivisionWithClass(
        division: row.readTable(divisions),
        classData: row.readTable(classes),
      );
    }).toList();
  }

  Stream<ClassDetail> watchClassDetail(int classId, int divisionId) {
    final query = select(classes).join([
      innerJoin(divisions, divisions.classId.equalsExp(classes.id)),
    ])
      ..where(classes.id.equals(classId) & divisions.id.equals(divisionId));

    return query.watch().map((rows) {
      if (rows.isEmpty) {
        throw StateError('Class or division not found');
      }
      final row = rows.first;
      return ClassDetail(
        cls: row.readTable(classes),
        division: row.readTable(divisions),
      );
    });
  }
}

class ClassDetail {
  final SchoolClass cls;
  final Division division;
  ClassDetail({required this.cls, required this.division});
}

class DivisionWithClass {
  final Division division;
  final SchoolClass classData;

  DivisionWithClass({required this.division, required this.classData});
}
