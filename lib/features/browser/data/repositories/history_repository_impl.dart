import 'package:drift/drift.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/core/services/database_service.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/models/page_transition.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({AppDatabase? db}) : _db = db ?? DatabaseService.db;

  final AppDatabase _db;

  SimpleSelectStatement<$HistoryEntriesView, BrowserHistory> _newestFirst(
    int? limit,
  ) {
    final query = _db.select(_db.historyEntries)
      ..orderBy([
        (h) => OrderingTerm.desc(h.timestamp),
        (h) => OrderingTerm.desc(h.id),
      ]);
    if (limit != null) query.limit(limit);
    return query;
  }

  @override
  Future<List<BrowserHistory>> getHistory({int? limit}) =>
      _newestFirst(limit).get();

  @override
  Future<List<BrowserHistory>> searchHistory(String query, {int? limit}) {
    final text = query.trim();
    if (text.isEmpty) return Future.value(const []);
    // Match the text literally: escape LIKE's own wildcards.
    final pattern =
        '%${text.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    return (_newestFirst(limit)..where(
          (h) =>
              h.url.like(pattern, escapeChar: r'\') |
              h.title.like(pattern, escapeChar: r'\'),
        ))
        .get();
  }

  @override
  Future<int> addVisit(
    String url, {
    PageTransition transition = PageTransition.link,
    int? fromVisit,
    DateTime? time,
  }) {
    final visitTime = (time ?? DateTime.now()).millisecondsSinceEpoch;
    final typed = transition == PageTransition.typed ? 1 : 0;
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.urls,
      )..where((u) => u.url.equals(url))).getSingleOrNull();

      final int urlId;
      if (existing == null) {
        urlId = await _db
            .into(_db.urls)
            .insert(
              UrlsCompanion.insert(
                url: url,
                visitCount: const Value(1),
                typedCount: Value(typed),
                lastVisitTime: visitTime,
              ),
            );
      } else {
        urlId = existing.id;
        await (_db.update(_db.urls)..where((u) => u.id.equals(urlId))).write(
          UrlsCompanion(
            visitCount: Value(existing.visitCount + 1),
            typedCount: Value(existing.typedCount + typed),
            lastVisitTime: Value(
              visitTime > existing.lastVisitTime
                  ? visitTime
                  : existing.lastVisitTime,
            ),
          ),
        );
      }

      return _db
          .into(_db.visits)
          .insert(
            VisitsCompanion.insert(
              urlId: urlId,
              visitTime: visitTime,
              transition: transition,
              fromVisit: Value(fromVisit),
            ),
          );
    });
  }

  @override
  Future<void> setTitle(String url, String title) => (_db.update(
    _db.urls,
  )..where((u) => u.url.equals(url))).write(UrlsCompanion(title: Value(title)));

  @override
  Future<void> deleteVisit(int visitId) => _db.transaction(() async {
    // Delete the visit with the redirect sources that led to it; they aren't
    // listed on their own and would otherwise show up in its place.
    final ids = <int>[];
    final urlIds = <int>{};
    int? next = visitId;
    while (next != null && !ids.contains(next)) {
      final id = next;
      final visit = await (_db.select(
        _db.visits,
      )..where((v) => v.id.equals(id))).getSingleOrNull();
      if (visit == null) break;
      ids.add(visit.id);
      urlIds.add(visit.urlId);
      next = visit.transition == PageTransition.redirect
          ? visit.fromVisit
          : null;
    }
    if (ids.isEmpty) return;
    await (_db.delete(_db.visits)..where((v) => v.id.isIn(ids))).go();
    await _recountUrls(urlIds: urlIds);
  });

  @override
  Future<void> clearHistory() => _db.delete(_db.urls).go(); // cascades

  @override
  Future<int> expireVisitsBefore(DateTime cutoff) => _db.transaction(() async {
    final deleted =
        await (_db.delete(_db.visits)..where(
              (v) =>
                  v.visitTime.isSmallerThanValue(cutoff.millisecondsSinceEpoch),
            ))
            .go();
    if (deleted > 0) await _recountUrls();
    return deleted;
  });

  /// Recomputes visit/typed counts and last visit time from the visits that
  /// remain, for [urlIds] or all URLs, and deletes URLs with no visits left.
  Future<void> _recountUrls({Set<int>? urlIds}) async {
    final filter = urlIds == null
        ? ''
        : ' WHERE id IN (${List.filled(urlIds.length, '?').join(', ')})';
    final args = [
      for (final id in urlIds ?? const <int>{}) Variable.withInt(id),
    ];
    await _db.customUpdate(
      'DELETE FROM urls'
      '${urlIds == null ? ' WHERE' : '$filter AND'} '
      'NOT EXISTS (SELECT 1 FROM visits WHERE url_id = urls.id)',
      variables: args,
      updates: {_db.urls, _db.visits},
      updateKind: UpdateKind.delete,
    );
    await _db.customUpdate(
      'UPDATE urls SET '
      'visit_count = (SELECT COUNT(*) FROM visits WHERE url_id = urls.id), '
      "typed_count = (SELECT COUNT(*) FROM visits WHERE url_id = urls.id AND transition = '${PageTransition.typed.name}'), "
      'last_visit_time = (SELECT MAX(visit_time) FROM visits WHERE url_id = urls.id)'
      '$filter',
      variables: args,
      updates: {_db.urls},
    );
  }
}
