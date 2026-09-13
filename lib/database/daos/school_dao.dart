import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'school_dao.g.dart';

@DriftAccessor(tables: [Schools, Admins])
class SchoolDao extends DatabaseAccessor<AppDatabase>
    with _$SchoolDaoMixin {
  SchoolDao(AppDatabase db) : super(db);

  Future<int> createSchool(SchoolsCompanion school) =>
      into(schools).insert(school);

  Future<bool> updateSchool(SchoolsCompanion school) =>
      update(schools).replace(school);

  Future<int> deleteSchool(int id) =>
      (delete(schools)..where((t) => t.id.equals(id))).go();

  Future<School?> getSchoolById(int id) =>
      (select(schools)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<School>> getAllSchools() => select(schools).get();

  Stream<List<School>> watchAllSchools() => select(schools).watch();

  Future<int> createAdmin(AdminsCompanion admin) =>
      into(admins).insert(admin);

  Future<bool> updateAdmin(AdminsCompanion admin) =>
      update(admins).replace(admin);

  Future<Admin?> getAdminByUsername(String username) =>
      (select(admins)..where((t) => t.username.equals(username)))
          .getSingleOrNull();

  Future<Admin?> getAdminById(int id) =>
      (select(admins)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Admin?> loginAdmin(String username, String passwordHash) =>
      (select(admins)..where((t) =>
              t.username.equals(username) &
              t.passwordHash.equals(passwordHash)))
          .getSingleOrNull();
}
