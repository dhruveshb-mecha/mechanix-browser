import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/features/browser/data/models/page_transition.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('migrations', () {
    test('v1 -> v2 adds the redirect-source index', () async {
      final dir = Directory.systemTemp.createTempSync('migration_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/browser.sqlite');

      // Make a v1 database: today's schema without the v2 index.
      final v1 = AppDatabase(NativeDatabase(file));
      await v1.customStatement('DROP INDEX visits_redirect_source');
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final names = await upgraded
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name = 'visits_redirect_source'",
          )
          .get();
      expect(names, hasLength(1));
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, 2);
    });
  });

  test('the history list reads the redirect index, not every visit', () async {
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM history_entries '
          'ORDER BY timestamp DESC LIMIT 50',
        )
        .get();
    final steps = plan.map((r) => r.read<String>('detail')).toList();
    expect(steps, contains(contains('visits_redirect_source')));
    expect(steps, isNot(contains('SCAN visits')));
  });

  Future<int> addUrl(String url, {String title = '', bool hidden = false}) => db
      .into(db.urls)
      .insert(
        UrlsCompanion.insert(
          url: url,
          title: Value(title),
          lastVisitTime: 0,
          hidden: Value(hidden),
        ),
      );

  Future<int> addVisit(
    int urlId,
    int time, {
    PageTransition transition = PageTransition.link,
    int? fromVisit,
  }) => db
      .into(db.visits)
      .insert(
        VisitsCompanion.insert(
          urlId: urlId,
          visitTime: time,
          transition: transition,
          fromVisit: Value(fromVisit),
        ),
      );

  test('creates the v1 schema', () async {
    final rows = await db
        .customSelect(
          "SELECT type, name FROM sqlite_master "
          "WHERE name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    expect(
      rows.map((r) => '${r.read<String>('type')}:${r.read<String>('name')}'),
      [
        'table:downloads',
        'index:downloads_cef_download_id',
        'view:history_entries',
        'table:tabs',
        'table:urls',
        'table:visits',
        'index:visits_from_visit',
        'index:visits_redirect_source',
        'index:visits_url_id',
        'index:visits_visit_time',
      ],
    );
    expect(db.schemaVersion, 2);
  });

  group('history', () {
    test('history_entries gives one BrowserHistory per visit', () async {
      final a = await addUrl('https://a.example/', title: 'A');
      final b = await addUrl('https://b.example/', title: 'B');
      final v1 = await addVisit(a, 100);
      final v2 = await addVisit(b, 200);
      final v3 = await addVisit(a, 300);

      final entries = await (db.select(
        db.historyEntries,
      )..orderBy([(h) => OrderingTerm.desc(h.timestamp)])).get();

      expect(entries.map((h) => (h.id, h.url, h.title, h.timestamp)), [
        (v3, 'https://a.example/', 'A', 300),
        (v2, 'https://b.example/', 'B', 200),
        (v1, 'https://a.example/', 'A', 100),
      ]);
    });

    test('hidden URLs are left out of history_entries', () async {
      final hop = await addUrl('https://redirect.example/', hidden: true);
      final dest = await addUrl('https://dest.example/');
      final first = await addVisit(hop, 100);
      await addVisit(
        dest,
        101,
        transition: PageTransition.redirect,
        fromVisit: first,
      );

      final entries = await db.select(db.historyEntries).get();
      expect(entries.map((h) => h.url), ['https://dest.example/']);
    });

    test('a URL is stored once', () async {
      await addUrl('https://a.example/');
      await expectLater(
        addUrl('https://a.example/'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('transition is stored by name', () async {
      await addVisit(
        await addUrl('https://a.example/'),
        1,
        transition: PageTransition.typed,
      );
      final raw = await db
          .customSelect('SELECT transition FROM visits')
          .getSingle();
      expect(raw.read<String>('transition'), 'typed');
    });

    test(
      'deleting a URL deletes its visits; redirect links are cleared',
      () async {
        final hop = await addUrl('https://hop.example/');
        final dest = await addUrl('https://dest.example/');
        final first = await addVisit(hop, 1);
        await addVisit(
          dest,
          2,
          transition: PageTransition.redirect,
          fromVisit: first,
        );

        await (db.delete(db.urls)..where((u) => u.id.equals(hop))).go();

        final visits = await db.select(db.visits).get();
        expect(visits, hasLength(1));
        expect(visits.single.urlId, dest);
        expect(visits.single.fromVisit, isNull);
      },
    );
  });

  test('download round-trips, including nullable fields', () async {
    final id = await db
        .into(db.downloads)
        .insert(
          DownloadEntity(
            cefDownloadId: 9,
            url: 'https://d.example/f.zip',
            fileName: 'f.zip',
            filePath: '/tmp/f.zip',
            statusIndex: 3,
            createdAt: 100,
            completedAt: 200,
            errorMessage: 'boom',
          ).toCompanion(),
        );
    expect(id, greaterThan(0), reason: 'id 0 must be left to SQLite');

    final d = await db.select(db.downloads).getSingle();
    expect(d.id, id);
    expect(d.cefDownloadId, 9);
    expect(d.totalBytes, -1);
    expect(d.downloadedBytes, 0);
    expect(d.statusIndex, 3);
    expect(d.completedAt, 200);
    expect(d.errorMessage, 'boom');
  });

  group('tabs', () {
    TabEntity tab(String tabId, {int id = 0, String title = 'T'}) => TabEntity(
      id: id,
      tabId: tabId,
      tabIndex: 0,
      url: 'https://t.example/',
      title: title,
      isActive: true,
      screenshot: Uint8List.fromList([1, 2, 3]),
    );

    test('round-trips the screenshot; tabId is unique', () async {
      await db.into(db.tabs).insert(tab('t1').toCompanion());
      final t = await db.select(db.tabs).getSingle();
      expect(t.tabId, 't1');
      expect(t.isActive, isTrue);
      expect(t.screenshot, [1, 2, 3]);

      await expectLater(
        db.into(db.tabs).insert(tab('t1').toCompanion()),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a stored id is kept, so writes update the existing row', () async {
      final id = await db.into(db.tabs).insert(tab('t1').toCompanion());
      await db
          .into(db.tabs)
          .insertOnConflictUpdate(
            tab('t1', id: id, title: 'new').toCompanion(),
          );

      final rows = await db.select(db.tabs).get();
      expect(rows.map((t) => (t.id, t.title)), [(id, 'new')]);
    });
  });
}
