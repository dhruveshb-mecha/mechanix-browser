import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/core/services/database_service.dart';

Future<Object?> pragma(AppDatabase db, String name) async =>
    (await db.customSelect('PRAGMA $name').getSingle()).data.values.single;

void main() {
  late Directory home;

  setUp(() => home = Directory.systemTemp.createTempSync('db_service_test'));
  tearDown(() async {
    await DatabaseService.close();
    home.deleteSync(recursive: true);
  });

  test('db throws before initialize', () {
    expect(() => DatabaseService.db, throwsStateError);
  });

  test('creates browser.sqlite in the profile dir, with WAL', () async {
    final db = await DatabaseService.initialize(homeDir: home.path);
    expect(DatabaseService.db, same(db));
    expect(
      await DatabaseService.initialize(homeDir: home.path),
      same(db),
      reason: 'initialize is idempotent',
    );

    final file = File(
      '${home.path}/.config/mechanix_apps/browser/browser.sqlite',
    );
    expect(file.existsSync(), isTrue);
    expect(await pragma(db, 'journal_mode'), 'wal');
    expect(await pragma(db, 'synchronous'), 1, reason: 'NORMAL');
    expect(await pragma(db, 'foreign_keys'), 1);
    expect(await pragma(db, 'user_version'), db.schemaVersion);
  });

  test('data persists across close and reopen', () async {
    var db = await DatabaseService.initialize(homeDir: home.path);
    await db
        .into(db.urls)
        .insert(UrlsCompanion.insert(url: 'https://a/', lastVisitTime: 1));
    await DatabaseService.close();
    expect(() => DatabaseService.db, throwsStateError);

    db = await DatabaseService.initialize(homeDir: home.path);
    final urls = await db.select(db.urls).get();
    expect(urls.map((u) => u.url), ['https://a/']);
  });

  test('an unusable database file fails initialize', () async {
    final file = File(
      '${home.path}/.config/mechanix_apps/browser/browser.sqlite',
    )..createSync(recursive: true);
    file.writeAsStringSync('this is not a database' * 100);

    await expectLater(
      DatabaseService.initialize(homeDir: home.path),
      throwsA(anything),
    );
    expect(() => DatabaseService.db, throwsStateError);
  });
}
