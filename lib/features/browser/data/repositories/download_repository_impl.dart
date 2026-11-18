import 'package:drift/drift.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/core/services/database_service.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl({AppDatabase? db}) : _db = db ?? DatabaseService.db;

  final AppDatabase _db;

  @override
  Future<List<DownloadEntity>> getAllDownloads() async {
    try {
      return await (_db.select(_db.downloads)..orderBy([
            (d) => OrderingTerm.desc(d.createdAt),
            (d) => OrderingTerm.desc(d.id),
          ]))
          .get();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to load download history: $e',
        error: e,
        stack: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<DownloadEntity?> getDownloadById(int id) => _orNull(
    'fetching download by id $id',
    () => (_db.select(
      _db.downloads,
    )..where((d) => d.id.equals(id))).getSingleOrNull(),
  );

  @override
  Future<DownloadEntity?> getDownloadByCefId(int cefDownloadId) => _orNull(
    'fetching download by CEF id $cefDownloadId',
    () =>
        (_db.select(_db.downloads)
              ..where((d) => d.cefDownloadId.equals(cefDownloadId))
              ..orderBy([(d) => OrderingTerm.desc(d.id)])
              ..limit(1))
            .getSingleOrNull(),
  );

  @override
  Future<int> saveDownload(DownloadEntity entity) async {
    try {
      return await _save(entity);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to save download entity (id=${entity.id}): $e',
        error: e,
        stack: stackTrace,
      );
      return 0;
    }
  }

  @override
  Future<List<int>> saveAllDownloads(List<DownloadEntity> entities) async {
    try {
      return await _db.transaction(() async {
        return [for (final entity in entities) await _save(entity)];
      });
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to batch save download entities: $e',
        error: e,
        stack: stackTrace,
      );
      return [];
    }
  }

  /// Inserts or updates [entity] and stores the id on it, like ObjectBox's
  /// `put` did.
  Future<int> _save(DownloadEntity entity) async {
    if (entity.id == 0) {
      entity.id = await _db.into(_db.downloads).insert(entity.toCompanion());
    } else {
      await _db
          .into(_db.downloads)
          .insertOnConflictUpdate(entity.toCompanion());
    }
    return entity.id;
  }

  @override
  Future<bool> deleteDownload(int id) async {
    try {
      final removed = await (_db.delete(
        _db.downloads,
      )..where((d) => d.id.equals(id))).go();
      if (removed == 0) {
        AppLogger.w(
          '[DownloadRepository] Attempted to delete record id=$id, but it was not found',
        );
      }
      return removed > 0;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to delete download entity $id: $e',
        error: e,
        stack: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      await _db.delete(_db.downloads).go();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to clear download history: $e',
        error: e,
        stack: stackTrace,
      );
    }
  }

  Future<T?> _orNull<T>(String what, Future<T?> Function() query) async {
    try {
      return await query();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Error $what: $e',
        error: e,
        stack: stackTrace,
      );
      return null;
    }
  }
}
