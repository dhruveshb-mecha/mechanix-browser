import 'dart:io';

import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:path/path.dart' as p;

/// Owns the app's single [AppDatabase], stored at
/// `$HOME/<AppConstants.profileDir>/<AppConstants.databaseFileName>`.
class DatabaseService {
  DatabaseService._();

  static AppDatabase? _db;

  /// The open database. Call [initialize] first (main.dart does).
  static AppDatabase get db =>
      _db ?? (throw StateError('DatabaseService.initialize() was not called'));

  /// Opens the database and runs any schema migrations, so failures show up
  /// at startup rather than on first use. Safe to call more than once.
  ///
  /// [homeDir] defaults to `$HOME`; tests pass a temporary directory.
  static Future<AppDatabase> initialize({String? homeDir}) async {
    if (_db != null) return _db!;

    final home = homeDir ?? Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('HOME environment variable is not set');
    }
    final file = File(
      p.join(home, AppConstants.profileDir, AppConstants.databaseFileName),
    );
    await file.parent.create(recursive: true);

    final db = AppDatabase.open(file);
    try {
      final mode = await db
          .customSelect('PRAGMA journal_mode')
          .map((row) => row.read<String>('journal_mode'))
          .getSingle();
      AppLogger.i('Opened ${file.path} (schema v${db.schemaVersion}, $mode)');
    } catch (e, stack) {
      AppLogger.e('Unable to open ${file.path}', error: e, stack: stack);
      await db.close();
      rethrow;
    }
    return _db = db;
  }

  static Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
