import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/features/browser/data/models/page_transition.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';

part 'app_database.g.dart';

// Times are milliseconds since the Unix epoch, as everywhere else in the app.
/// One row per unique URL (Chromium's `urls` table).
@DataClassName('HistoryUrl')
class Urls extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().unique()();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Number of visits to this URL.
  IntColumn get visitCount => integer().withDefault(const Constant(0))();

  /// Number of those visits where the URL was typed in the address bar.
  IntColumn get typedCount => integer().withDefault(const Constant(0))();
  IntColumn get lastVisitTime => integer()();

  /// Hidden URLs are kept for counting but not shown in history or
  /// suggestions. Reserved, as in Chromium (e.g. for subframe-only URLs);
  /// nothing sets it yet. Redirect hops are left out per visit instead.
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
}

/// One row per visit to a URL (Chromium's `visits` table).
@DataClassName('HistoryVisit')
@TableIndex(name: 'visits_url_id', columns: {#urlId})
@TableIndex(name: 'visits_visit_time', columns: {#visitTime})
@TableIndex(name: 'visits_from_visit', columns: {#fromVisit})
// Only redirect rows, so the history list's "not a redirect source" filter
// (see _IsRedirectChainEnd) reads a small index instead of every visit.
@TableIndex.sql(
  "CREATE INDEX visits_redirect_source ON visits (from_visit) "
  "WHERE transition = 'redirect'",
)
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get urlId =>
      integer().references(Urls, #id, onDelete: KeyAction.cascade)();
  IntColumn get visitTime => integer()();
  TextColumn get transition => textEnum<PageTransition>()();

  /// The visit this one came from, for redirect chains.
  IntColumn get fromVisit => integer().nullable().references(
    Visits,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

/// Visits joined with their URL, as the history list shows them: one
/// [BrowserHistory] per visit (`id` is the visit id), hidden URLs left out.
@DriftView(name: 'history_entries')
@UseRowClass(BrowserHistory)
abstract class HistoryEntries extends View {
  Visits get visits;
  Urls get urls;

  Expression<int> get timestamp => visits.visitTime;

  @override
  Query as() =>
      select([visits.id, urls.url, urls.title, timestamp]).from(visits).join([
        innerJoin(urls, urls.id.equalsExp(visits.urlId)),
      ])..where(urls.hidden.not() & _IsRedirectChainEnd(visits.id));
}

/// True unless the visit [visitId] redirected onward: like Chromium, history
/// lists where a redirect chain ended.
///
/// Renders `<visitId> NOT IN (SELECT from_visit ...)`. Drift writes the
/// column itself, since it aliases the view's tables (`"t0"."id"`).
class _IsRedirectChainEnd extends Expression<bool> {
  const _IsRedirectChainEnd(this.visitId);

  final Expression<int> visitId;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, visitId);
    context.buffer.write(
      ' NOT IN (SELECT from_visit FROM visits '
      "WHERE transition = 'redirect' AND from_visit IS NOT NULL)",
    );
  }
}

@UseRowClass(DownloadEntity)
@TableIndex(name: 'downloads_cef_download_id', columns: {#cefDownloadId})
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cefDownloadId => integer()();
  TextColumn get url => text()();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  IntColumn get totalBytes => integer().withDefault(const Constant(-1))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  /// `DownloadStatus.index`.
  IntColumn get statusIndex => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
}

@UseRowClass(TabEntity)
class Tabs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tabId => text().unique()();
  IntColumn get tabIndex => integer()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  BoolColumn get isActive => boolean()();
  BlobColumn get screenshot => blob().nullable()();
}

@DriftDatabase(tables: [Urls, Visits, Downloads, Tabs], views: [HistoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the database in [file], running SQLite on a background isolate so
  /// queries never block the UI.
  factory AppDatabase.open(File file) =>
      AppDatabase(NativeDatabase.createInBackground(file, setup: _setup));

  static void _setup(Database db) {
    // WAL lets history writes and UI reads run at the same time. With WAL,
    // synchronous=NORMAL can only lose the last commits on power loss, never
    // corrupt the database.
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = NORMAL');
  }

  /// Bump on every schema change and add the matching step to [migration].
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // One step per version.
      if (from < 2) await m.createIndex(visitsRedirectSource);
    },
    // SQLite leaves foreign keys off per connection; visits rely on them for
    // ON DELETE CASCADE / SET NULL.
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

Value<int> _idValue(int id) => id == 0 ? const Value.absent() : Value(id);

extension DownloadEntityToCompanion on DownloadEntity {
  DownloadsCompanion toCompanion() => DownloadsCompanion(
    id: _idValue(id),
    cefDownloadId: Value(cefDownloadId),
    url: Value(url),
    fileName: Value(fileName),
    filePath: Value(filePath),
    totalBytes: Value(totalBytes),
    downloadedBytes: Value(downloadedBytes),
    statusIndex: Value(statusIndex),
    createdAt: Value(createdAt),
    completedAt: Value(completedAt),
    errorMessage: Value(errorMessage),
  );
}

extension TabEntityToCompanion on TabEntity {
  TabsCompanion toCompanion() => TabsCompanion(
    id: _idValue(id),
    tabId: Value(tabId),
    tabIndex: Value(tabIndex),
    url: Value(url),
    title: Value(title),
    isActive: Value(isActive),
    screenshot: Value(screenshot),
  );
}
