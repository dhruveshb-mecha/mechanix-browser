import 'package:drift/drift.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/core/services/database_service.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';

/// The normal (non-private) tabs, saved so they can be restored on the next
/// start.
class TabRepository {
  TabRepository({AppDatabase? db}) : _db = db ?? DatabaseService.db;

  final AppDatabase _db;

  /// Saved tabs in tab order; empty if they can't be read.
  Future<List<TabEntity>> getAllTabs() async {
    try {
      return await (_db.select(
        _db.tabs,
      )..orderBy([(t) => OrderingTerm.asc(t.tabIndex)])).get();
    } catch (e, stackTrace) {
      AppLogger.e('Unable to get tabs', error: e, stack: stackTrace);
      return [];
    }
  }

  /// Replaces the saved tabs with [tabs], atomically.
  Future<void> replaceAllTabs(List<TabEntity> tabs) => _db.batch((batch) {
    batch.deleteAll(_db.tabs);
    batch.insertAll(_db.tabs, [for (final tab in tabs) tab.toCompanion()]);
  });
}
