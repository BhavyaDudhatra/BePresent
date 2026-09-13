import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

class BackupService {
  final AppDatabase _db;
  final void Function() _reloadDb;

  BackupService(this._db, this._reloadDb);

  Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'be_present.sqlite');
  }

  Future<File> createBackup() async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(dir.path, 'be_present_backup_$timestamp.db');
    final escaped = path.replaceAll("'", "''");
    await _db.customStatement("VACUUM INTO '$escaped'");
    return File(path);
  }

  Future<bool> isValidBackup(String path) async {
    try {
      final bytes = await File(path).openRead(0, 16).first;
      if (bytes.length < 16) return false;
      final magic = String.fromCharCodes(bytes.sublist(0, 15));
      return magic.startsWith('SQLite format');
    } catch (_) {
      return false;
    }
  }

  /// Replaces the live database with the file at [path].
  /// Returns false if the file is not a valid SQLite backup.
  Future<bool> restoreFrom(String path) async {
    if (!await isValidBackup(path)) return false;
    final target = await _dbPath();
    final currentBackup = File('$target.restore.bak');
    try {
      await _db.close();
      if (await currentBackup.exists()) await currentBackup.delete();
      if (await File(target).exists()) {
        await File(target).copy(currentBackup.path);
      }
      await File(path).copy(target);
      _reloadDb();
      return true;
    } catch (_) {
      try {
        if (await currentBackup.exists()) {
          await File(target).delete();
          await currentBackup.copy(target);
        }
      } catch (_) {}
      _reloadDb();
      return false;
    }
  }

  Future<void> shareBackup() async {
    final file = await createBackup();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/x-sqlite3')],
        subject: 'Be Present backup',
        text: 'Backup of the Be Present database',
      ),
    );
  }
}