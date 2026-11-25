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

  /// Makes the saved tabs match [tabs], atomically: tabs no longer open are
  /// deleted, the rest inserted or updated by `tabId`.
  Future<void> saveTabs(List<TabEntity> tabs) => _db.batch((batch) {
    batch.deleteWhere(
      _db.tabs,
      (t) => t.tabId.isNotIn([for (final tab in tabs) tab.tabId]),
    );
    for (final tab in tabs) {
      final row = tab.toCompanion().copyWith(id: const Value.absent());
      batch.insert(
        _db.tabs,
        row,
        onConflict: DoUpdate((_) => row, target: [_db.tabs.tabId]),
      );
    }
  });
}
