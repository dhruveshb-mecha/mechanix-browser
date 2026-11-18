import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/services/bookmark_service.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/bookmarks/bookmark_model.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/data/repositories/bookmark_repository.dart';

Bookmark bookmark(
  String url, {
  BookmarkType type = BookmarkType.bookmark,
  String? title,
  String? iconUrl,
  int timestamp = 1000,
  double score = 0,
}) => Bookmark.create(
  url: url,
  title: title,
  iconUrl: iconUrl,
  timestamp: timestamp,
  type: type,
  score: score,
);

/// A bloc without BrowserInitialized (which opens ObjectBox and CEF).
class SeededBrowserBloc extends BrowserBloc {
  SeededBrowserBloc(BookmarkRepository bookmarks)
    : super(bookmarkRepository: bookmarks) {
    emit(const BrowserState.initial().copyWith(isInitialized: true));
  }
}

void main() {
  late Directory dir;
  late File file;
  late BookmarkModel model;
  late BookmarkRepository repository;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('bookmark_repo_test');
    file = File('${dir.path}/Bookmarks');
    model = await BookmarkModel.load(file);
    repository = BookmarkRepository(model: model);
  });
  tearDown(() async {
    await model.close();
    dir.deleteSync(recursive: true);
  });

  test('favorites go in the bookmark bar, bookmarks in other', () {
    final fav = bookmark(
      'https://fav/',
      type: BookmarkType.favorite,
      title: 'Fav',
      iconUrl: 'https://fav/icon.png',
      timestamp: 1700000000000,
    );
    final id = repository.addOrUpdate(fav);
    repository.addOrUpdate(bookmark('https://bm/'));

    expect(fav.id, id);
    expect(model.bookmarkBar.children.single.url, 'https://fav/');
    expect(model.other.children.single.url, 'https://bm/');

    final [f] = repository.getFavorites();
    expect(
      (f.id, f.url, f.title, f.iconUrl, f.timestamp, f.type),
      (
        id,
        'https://fav/',
        'Fav',
        'https://fav/icon.png',
        1700000000000,
        BookmarkType.favorite,
      ),
    );
    final [b] = repository.getBookmarks();
    expect((b.title, b.iconUrl, b.type), (null, null, BookmarkType.bookmark));
  });

  test('adding the same URL and type again updates the entry', () {
    final id = repository.addOrUpdate(bookmark('https://a/', title: 'Old'));
    final again = bookmark('https://a/', title: 'New', iconUrl: 'i');
    expect(repository.addOrUpdate(again), id);

    final [a] = repository.getBookmarks();
    expect((a.id, a.title, a.iconUrl), (id, 'New', 'i'));

    // The same URL as a favorite is a separate entry.
    repository.addOrUpdate(bookmark('https://a/', type: BookmarkType.favorite));
    expect(repository.getFavorites(), hasLength(1));
    expect(repository.getBookmarks(), hasLength(1));
  });

  test('isSaved, remove and removeByUrlAndType respect the type', () {
    final id = repository.addOrUpdate(bookmark('https://a/'));
    repository.addOrUpdate(bookmark('https://a/', type: BookmarkType.favorite));

    expect(repository.isBookmarked('https://a/'), isTrue);
    expect(repository.isSaved('https://a/', BookmarkType.favorite), isTrue);
    expect(repository.isBookmarked('https://other/'), isFalse);

    expect(
      repository.removeByUrlAndType('https://a/', BookmarkType.favorite),
      isTrue,
    );
    expect(repository.isSaved('https://a/', BookmarkType.favorite), isFalse);
    expect(repository.isBookmarked('https://a/'), isTrue);
    expect(
      repository.removeByUrlAndType('https://a/', BookmarkType.favorite),
      isFalse,
    );

    expect(repository.remove(id), isTrue);
    expect(repository.remove(id), isFalse);
    expect(repository.remove(model.other.id), isFalse, reason: 'not a URL');
    expect(repository.queryBookmarks(), isEmpty);
  });

  test('sorts by timestamp or score, newest/highest first by default', () {
    repository.addOrUpdate(bookmark('https://1/', timestamp: 10, score: 3));
    repository.addOrUpdate(bookmark('https://2/', timestamp: 30, score: 1));
    repository.addOrUpdate(bookmark('https://3/', timestamp: 20, score: 2));

    List<String> urls(List<Bookmark> list) => [for (final b in list) b.url];
    expect(urls(repository.getBookmarks()), [
      'https://2/',
      'https://3/',
      'https://1/',
    ]);
    expect(urls(repository.getBookmarks(descending: false)), [
      'https://1/',
      'https://3/',
      'https://2/',
    ]);
    expect(urls(repository.getBookmarks(sortBy: BookmarkSortBy.score)), [
      'https://1/',
      'https://3/',
      'https://2/',
    ]);
    expect(repository.getBookmarks().first.score, 1);
  });

  test('entries in folders and in "Mobile bookmarks" are listed', () {
    final folder = model.addFolder(model.other, 'Work');
    model.addUrl(folder, title: 'Docs', url: 'https://docs/');
    model.addUrl(model.synced, title: 'Phone', url: 'https://phone/');
    model.addUrl(
      model.addFolder(model.bookmarkBar, 'Bar folder'),
      title: 'Fav in folder',
      url: 'https://favfolder/',
    );

    expect(repository.getBookmarks().map((b) => b.url).toSet(), {
      'https://docs/',
      'https://phone/',
    });
    expect(repository.getFavorites().single.type, BookmarkType.favorite);
    expect(repository.isBookmarked('https://docs/'), isTrue);
  });

  test('entries are saved to the Bookmarks file and reload', () async {
    repository.addOrUpdate(
      bookmark(
        'https://fav/',
        type: BookmarkType.favorite,
        title: 'Fav',
        iconUrl: 'https://fav/i.png',
        score: 2.5,
      ),
    );
    await model.flush();

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final node = json['roots']['bookmark_bar']['children'][0];
    expect(node['meta_info'], {
      'icon_url': 'https://fav/i.png',
      'score': '2.5',
    });

    final reloaded = BookmarkRepository(model: await BookmarkModel.load(file));
    final [f] = reloaded.getFavorites();
    expect(
      (f.url, f.title, f.iconUrl, f.score),
      ('https://fav/', 'Fav', 'https://fav/i.png', 2.5),
    );
  });

  group('BrowserBloc', () {
    // The bloc is not closed: close() shuts down CEF, which isn't running.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    test('toggling bookmarks a page, toggling again removes it', () async {
      final bloc = SeededBrowserBloc(repository);
      bloc.add(const BrowserBookmarkToggled(url: 'https://a/', title: 'A'));
      await settle();
      expect(bloc.state.bookmarks.single.title, 'A');
      expect(repository.isBookmarked('https://a/'), isTrue);

      bloc.add(const BrowserBookmarkToggled(url: 'https://a/'));
      await settle();
      expect(bloc.state.bookmarks, isEmpty);
    });

    test('favorites are added and removed by id', () async {
      final bloc = SeededBrowserBloc(repository);
      bloc.add(
        const BrowserBookmarkAdded(
          url: 'https://fav/',
          label: 'Fav',
          type: BookmarkType.favorite,
        ),
      );
      await settle();
      final [fav] = bloc.state.favorites;
      expect((fav.title, fav.iconUrl), ('Fav', 'https://fav/'));

      bloc.add(BrowserBookmarkRemoved(id: fav.id, type: BookmarkType.favorite));
      await settle();
      expect(bloc.state.favorites, isEmpty);
    });
  });

  group('BookmarkService', () {
    tearDown(BookmarkService.close);

    test(
      'loads Bookmarks from the profile dir and flushes on demand',
      () async {
        expect(() => BookmarkService.model, throwsStateError);
        final m = await BookmarkService.initialize(homeDir: dir.path);
        expect(await BookmarkService.initialize(homeDir: dir.path), same(m));

        m.addUrl(m.other, title: 'A', url: 'https://a/');
        await BookmarkService.flush();
        expect(
          File(
            '${dir.path}/.config/mechanix_apps/browser/Bookmarks',
          ).readAsStringSync(),
          contains('https://a/'),
        );
      },
    );
  });
}
