import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<String> getValueOr(String key, String defaultValue) async {
    return (await getValue(key)) ?? defaultValue;
  }

  Future<void> setValue(String key, String value) async {
    await into(settings).insert(
      SettingsCompanion.insert(key: key, value: Value(value)),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeValue(String key) async {
    await (delete(settings)..where((t) => t.key.equals(key))).go();
  }

  Stream<String?> watchValue(String key) {
    return (select(settings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((r) => r?.value);
  }
}