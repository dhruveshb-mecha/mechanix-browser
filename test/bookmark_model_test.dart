import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/utils/important_file_writer.dart';
import 'package:mechanix_browser/features/browser/data/bookmarks/bookmark_model.dart';

/// A small file in Chromium's layout.
String sampleFile() => jsonEncode({
  'roots': {
    'bookmark_bar': {
      'children': [
        {
          'date_added': '13348540800000000', // 2024-01-01 UTC
          'id': '4',
          'meta_info': {'icon_url': 'https://coffee.example/icon.png'},
          'name': 'Café ☕',
          'type': 'url',
          'url': 'https://coffee.example/',
        },
        {
          'children': [
            {
              'date_added': '13348540800000000',
              'id': '6',
              'name': 'Docs',
              'type': 'url',
              'url': 'https://docs.example/',
            },
            {'id': '7', 'name': 'bad type', 'type': 'bogus'},
            {'id': '8', 'name': 'no url', 'type': 'url'},
          ],
          'date_added': '13348540800000000',
          'id': '5',
          'name': 'Work',
          'type': 'folder',
        },
      ],
      'date_added': '13348540800000000',
      'id': '1',
      'name': 'Bookmarks bar',
      'type': 'folder',
    },
    'other': {
      'children': [],
      'id': '2',
      'name': 'Other bookmarks',
      'type': 'folder',
    },
    'synced': {
      'children': [],
      'id': '3',
      'name': 'Mobile bookmarks',
      'type': 'folder',
    },
  },
  'version': 1,
});

/// Structural snapshot of a tree, for comparing two trees.
List<Object?> snapshot(BookmarkNode n) => [
  n.id,
  n.type,
  n.title,
  n.url,
  n.dateAdded,
  n.metaInfo,
  [for (final c in n.children) snapshot(c)],
];

Future<void> waitFor(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bookmarks_test');
    file = File('${dir.path}/Bookmarks');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('BookmarkModel', () {
    test('a missing file gives empty roots and writes nothing', () async {
      final model = await BookmarkModel.load(file);
      expect(model.roots.map((r) => (r.id, r.title, r.children.length)), [
        (1, 'Bookmarks bar', 0),
        (2, 'Other bookmarks', 0),
        (3, 'Mobile bookmarks', 0),
      ]);
      expect(model.hasPendingSave, isFalse);
      await model.close();
      expect(file.existsSync(), isFalse);
    });

    test('loads a Chromium-layout file, skipping unusable nodes', () async {
      file.writeAsStringSync(sampleFile());
      final model = await BookmarkModel.load(file);

      final [coffee, work] = model.bookmarkBar.children;
      expect(coffee.title, 'Café ☕');
      expect(coffee.url, 'https://coffee.example/');
      expect(coffee.dateAdded, DateTime.utc(2024));
      expect(coffee.metaInfo, {'icon_url': 'https://coffee.example/icon.png'});
      expect(work.children.map((n) => n.title), ['Docs']);
      expect(work.children.single.parent, same(work));
      expect(model.nodeById(6), same(work.children.single));
      expect(model.isBookmarked('https://docs.example/'), isTrue);
      expect(model.bookmarkBar.isPermanent, isTrue);
      expect(coffee.isPermanent, isFalse);
      // New ids continue after the largest stored one.
      expect(model.addFolder(model.other, 'n').id, 7);
      await model.close();
    });

    test('writes Chromium\'s layout', () async {
      final model = await BookmarkModel.load(file);
      model.addUrl(
        model.other,
        title: 'A',
        url: 'https://a/',
        dateAdded: DateTime.utc(2024),
        metaInfo: {'icon_url': 'i'},
      );
      await model.close();

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json.keys, ['roots', 'version']);
      expect(json['version'], 1);
      expect((json['roots'] as Map).keys, ['bookmark_bar', 'other', 'synced']);
      expect(json['roots']['other']['children'], [
        {
          'date_added': '13348540800000000',
          'id': '4',
          'meta_info': {'icon_url': 'i'},
          'name': 'A',
          'type': 'url',
          'url': 'https://a/',
        },
      ]);
    });

    test('edits update the tree, the indexes and the change stream', () async {
      final model = await BookmarkModel.load(file);
      var changes = 0;
      model.changes.listen((_) => changes++);

      final a = model.addUrl(model.bookmarkBar, title: 'A', url: 'https://a/');
      final folder = model.addFolder(model.other, 'F');
      final b = model.addUrl(folder, title: 'B', url: 'https://b/');
      final a2 = model.addUrl(
        model.other,
        title: 'A2',
        url: 'https://a/',
        index: 0,
      );

      expect([a.id, folder.id, b.id, a2.id], [4, 5, 6, 7]);
      expect(model.other.children, [a2, folder]);
      expect(model.nodesForUrl('https://a/'), unorderedEquals([a, a2]));

      model.setUrl(b, 'https://b2/');
      expect(model.isBookmarked('https://b/'), isFalse);
      expect(model.isBookmarked('https://b2/'), isTrue);
      model.setTitle(a, 'A!');
      model.setMetaInfo(a, 'icon_url', 'x');
      model.setMetaInfo(a, 'icon_url', null);
      expect(a.metaInfo, isEmpty);

      model.remove(folder);
      expect(model.nodeById(b.id), isNull);
      expect(model.isBookmarked('https://b2/'), isFalse);
      expect(model.other.children, [a2]);

      expect(() => model.remove(model.other), throwsArgumentError);
      expect(() => model.setTitle(model.other, 'x'), throwsArgumentError);
      expect(
        () => model.addUrl(a, title: 'in a url', url: 'u'),
        throwsArgumentError,
      );

      await Future<void>.delayed(Duration.zero);
      expect(changes, 9);
      await model.close();
    });

    test('saves after the delay and reloads identically', () async {
      final model = await BookmarkModel.load(
        file,
        saveDelay: const Duration(milliseconds: 50),
      );
      final f = model.addFolder(model.bookmarkBar, 'Work');
      model.addUrl(
        f,
        title: 'Docs',
        url: 'https://docs/',
        metaInfo: {'k': 'v'},
      );
      model.addUrl(model.other, title: 'O', url: 'https://o/');
      expect(model.hasPendingSave, isTrue);
      expect(file.existsSync(), isFalse);

      await waitFor(() => !model.hasPendingSave && file.existsSync());
      await model.flush();

      final reloaded = await BookmarkModel.load(file);
      for (var i = 0; i < 3; i++) {
        expect(snapshot(reloaded.roots[i]), snapshot(model.roots[i]));
      }
      await model.close();
      await reloaded.close();
    });

    test('by default a change is on disk right after it is made', () async {
      final model = await BookmarkModel.load(file);
      model.addUrl(model.bookmarkBar, title: 'Fav', url: 'https://fav/');
      model.addUrl(model.other, title: 'B', url: 'https://b/');
      await waitFor(() => !model.hasPendingSave && file.existsSync());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final text = file.readAsStringSync();
      expect(text, contains('https://fav/'));
      expect(text, contains('https://b/'));
      await model.close();
    });

    test('flush writes pending changes at once', () async {
      final model = await BookmarkModel.load(
        file,
        saveDelay: const Duration(seconds: 10),
      );
      model.addUrl(model.other, title: 'A', url: 'https://a/');
      await model.flush();
      expect(model.hasPendingSave, isFalse);
      expect(file.readAsStringSync(), contains('https://a/'));
      await model.close();
    });

    test(
      'keeps the previous file as Bookmarks.bak, once per session',
      () async {
        file.writeAsStringSync(sampleFile());
        final model = await BookmarkModel.load(file);
        model.addUrl(model.other, title: 'A', url: 'https://a/');
        await model.flush();
        model.addUrl(model.other, title: 'B', url: 'https://b/');
        await model.flush();

        expect(File('${file.path}.bak').readAsStringSync(), sampleFile());
        expect(file.readAsStringSync(), contains('https://b/'));
        await model.close();
      },
    );

    test('an unreadable file is kept aside and the backup is used', () async {
      file.writeAsStringSync('{"version": 1, "roots": {');
      File('${file.path}.bak').writeAsStringSync(sampleFile());

      final model = await BookmarkModel.load(file);
      expect(
        File('${file.path}.corrupt').readAsStringSync(),
        '{"version": 1, "roots": {',
      );
      expect(model.bookmarkBar.children, hasLength(2));
      expect(model.hasPendingSave, isTrue, reason: 'restore the main file');
      await model.close();
      expect(file.readAsStringSync(), contains('coffee.example'));
    });

    test('an unreadable file without a backup gives empty roots', () async {
      file.writeAsStringSync(jsonEncode({'version': 2, 'roots': {}}));
      final model = await BookmarkModel.load(file);
      expect(model.roots.every((r) => r.children.isEmpty), isTrue);
      expect(File('${file.path}.corrupt').existsSync(), isTrue);
      await model.close();
    });
  });

  group('ImportantFileWriter', () {
    test('replaces the file and leaves no temporary files', () async {
      file.writeAsStringSync('old');
      await ImportantFileWriter.writeFileAtomically(file, 'new');
      expect(file.readAsStringSync(), 'new');
      expect(dir.listSync().map((e) => e.uri.pathSegments.last), ['Bookmarks']);
    });

    test('a burst is one write, timed from its first change', () async {
      final writer = ImportantFileWriter(
        file,
        commitInterval: const Duration(milliseconds: 500),
      );
      final calls = <String>[];
      final start = DateTime.now();
      writer.scheduleWrite(() => (calls..add('first')).last);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      writer.scheduleWrite(() => (calls..add('second')).last);

      await waitFor(() => !writer.hasPendingWrite);
      final elapsed = DateTime.now().difference(start);
      await writer.flush();

      expect(calls, ['second'], reason: 'only the latest serializer runs');
      expect(file.readAsStringSync(), 'second');
      // A restarted timer would fire at ~750 ms.
      expect(elapsed, lessThan(const Duration(milliseconds: 700)));
    });
  });
}
