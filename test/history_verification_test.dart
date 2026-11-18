import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/data/models/page_transition.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';
import 'package:webview_cef/webview_cef.dart';

DateTime at(int minutes) =>
    DateTime.utc(2026, 1, 1).add(Duration(minutes: minutes));

Future<List<HistoryUrl>> urlRows(AppDatabase db) =>
    (db.select(db.urls)..orderBy([(u) => OrderingTerm.asc(u.id)])).get();

Future<List<HistoryVisit>> visitRows(AppDatabase db) =>
    (db.select(db.visits)..orderBy([(v) => OrderingTerm.asc(v.id)])).get();

Future<void> waitFor(Future<bool> Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!await done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

BrowserTab tab(String id, {bool private = false}) => BrowserTab(
  id: id,
  controller: WebViewController(const MethodChannel('test'), id.hashCode),
  currentUrl: '',
  title: '',
  isHomePage: true,
  isLoading: false,
  isPrivate: private,
);

/// A bloc with one normal tab `t1` and one private tab `p1`, without going
/// through BrowserInitialized (which opens ObjectBox and CEF).
class SeededBrowserBloc extends BrowserBloc {
  SeededBrowserBloc(HistoryRepository repository)
    : super(historyRepository: repository) {
    emit(
      const BrowserState.initial().copyWith(
        isInitialized: true,
        normalTabs: [tab('t1')],
        privateTabs: [tab('p1', private: true)],
        activeNormalTabIndex: 0,
      ),
    );
  }
}

void main() {
  late AppDatabase db;
  late HistoryRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = HistoryRepositoryImpl(db: db);
  });
  tearDown(() => db.close());

  group('HistoryRepository', () {
    test('records one URL row and one visit per visit', () async {
      await repository.addVisit('https://a/', time: at(1));
      await repository.addVisit(
        'https://a/',
        transition: PageTransition.typed,
        time: at(3),
      );
      await repository.addVisit('https://b/', time: at(2));

      final history = await repository.getHistory();
      expect(history.map((h) => (h.url, h.timestamp)), [
        ('https://a/', at(3).millisecondsSinceEpoch),
        ('https://b/', at(2).millisecondsSinceEpoch),
        ('https://a/', at(1).millisecondsSinceEpoch),
      ]);
      expect((await repository.getHistory(limit: 1)), hasLength(1));

      final [a, b] = await urlRows(db);
      expect((a.url, a.visitCount, a.typedCount), ('https://a/', 2, 1));
      expect(a.lastVisitTime, at(3).millisecondsSinceEpoch);
      expect((b.url, b.visitCount, b.typedCount), ('https://b/', 1, 0));
      expect((await visitRows(db)).map((v) => v.transition), [
        PageTransition.link,
        PageTransition.typed,
        PageTransition.link,
      ]);
    });

    test('setTitle applies to every visit of the URL', () async {
      await repository.addVisit('https://a/', time: at(1));
      await repository.addVisit('https://a/', time: at(2));
      await repository.setTitle('https://a/', 'A');
      await repository.setTitle('https://missing/', 'ignored');

      expect((await repository.getHistory()).map((h) => h.title), ['A', 'A']);
    });

    test(
      'search matches URL or title, any case, wildcards literally',
      () async {
        await repository.addVisit('https://github.com/', time: at(1));
        await repository.setTitle('https://github.com/', 'GitHub');
        await repository.addVisit('https://example.com/100%', time: at(2));
        await repository.addVisit('https://example.com/a_b', time: at(3));

        Future<List<String>> search(String q) async =>
            (await repository.searchHistory(q)).map((h) => h.url).toList();

        expect(await search('HUB'), ['https://github.com/']);
        expect(await search('github.COM'), ['https://github.com/']);
        expect(await search('100%'), ['https://example.com/100%']);
        expect(await search('%'), ['https://example.com/100%']);
        expect(await search('a_b'), ['https://example.com/a_b']);
        expect(await search('_'), ['https://example.com/a_b']);
        expect(await search('  '), isEmpty);
        expect(await search('nothing'), isEmpty);
      },
    );

    Future<int> redirect(String url, int from, int minute) =>
        repository.addVisit(
          url,
          transition: PageTransition.redirect,
          fromVisit: from,
          time: at(minute),
        );

    Future<List<String>> listed() async =>
        (await repository.getHistory()).map((h) => h.url).toList();

    test('a visit that redirected onward is not listed', () async {
      final first = await repository.addVisit('https://short/', time: at(1));
      await redirect('https://long/', first, 1);

      expect(await listed(), ['https://long/']);
      expect((await visitRows(db)).last.fromVisit, first);

      // Visiting it directly is listed; the redirecting visit still isn't.
      await repository.addVisit('https://short/', time: at(2));
      expect(await listed(), ['https://short/', 'https://long/']);
    });

    test('only the redirecting visit of a URL is left out', () async {
      await repository.addVisit('https://short/', time: at(1));
      final source = await repository.addVisit('https://short/', time: at(2));
      await redirect('https://long/', source, 2);
      expect(await listed(), ['https://long/', 'https://short/']);
    });

    test('a redirect ping-pong lists only where it ended', () async {
      // As CEF reported for a meta-refresh page opened from the command line.
      final v1 = await repository.addVisit('https://start/', time: at(1));
      final v2 = await redirect('https://dest/', v1, 1);
      final v3 = await redirect('https://start/', v2, 1);
      await redirect('https://dest/', v3, 1);
      expect(await listed(), ['https://dest/']);
    });

    test('deleting a listed visit deletes its redirect sources', () async {
      await repository.addVisit('https://earlier/', time: at(1));
      final v1 = await repository.addVisit(
        'https://short/',
        transition: PageTransition.typed,
        time: at(2),
      );
      final v2 = await redirect('https://mid/', v1, 2);
      final v3 = await redirect('https://long/', v2, 2);

      await repository.deleteVisit(v3);
      expect(await listed(), ['https://earlier/']);
      expect((await urlRows(db)).map((u) => u.url), ['https://earlier/']);
    });

    test('deleting visits updates counts and drops empty URLs', () async {
      final v1 = await repository.addVisit(
        'https://a/',
        transition: PageTransition.typed,
        time: at(1),
      );
      final v2 = await repository.addVisit('https://a/', time: at(2));

      await repository.deleteVisit(v2);
      final [a] = await urlRows(db);
      expect((a.visitCount, a.typedCount), (1, 1));
      expect(a.lastVisitTime, at(1).millisecondsSinceEpoch);

      await repository.deleteVisit(v1);
      expect(await urlRows(db), isEmpty);
      await repository.deleteVisit(999); // unknown: no-op
    });

    test('clearHistory removes everything', () async {
      await repository.addVisit('https://a/', time: at(1));
      await repository.addVisit('https://b/', time: at(2));
      await repository.clearHistory();
      expect(await repository.getHistory(), isEmpty);
      expect(await urlRows(db), isEmpty);
      expect(await visitRows(db), isEmpty);
    });

    test('expiry deletes old visits and recounts URLs', () async {
      await repository.addVisit('https://old/', time: at(1));
      await repository.addVisit('https://both/', time: at(2));
      await repository.addVisit('https://both/', time: at(20));
      await repository.addVisit('https://new/', time: at(30));

      expect(await repository.expireVisitsBefore(at(10)), 2);
      expect(await repository.expireVisitsBefore(at(10)), 0);

      final urls = await urlRows(db);
      expect(urls.map((u) => (u.url, u.visitCount)), [
        ('https://both/', 1),
        ('https://new/', 1),
      ]);
      expect(urls.first.lastVisitTime, at(20).millisecondsSinceEpoch);
    });
  });

  group('BrowserBloc history', () {
    late SeededBrowserBloc bloc;

    setUp(() => bloc = SeededBrowserBloc(repository));
    // The bloc is not closed: close() shuts down CEF, which isn't running.

    Future<List<HistoryVisit>> visitsWhen(int count) async {
      await waitFor(() async => (await visitRows(db)).length >= count);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return visitRows(db);
    }

    test('a page visit is recorded as a link, with its title', () async {
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://a/'));
      bloc.add(const BrowserTitleChanged(tabId: 't1', title: 'Page A'));

      await waitFor(
        () async =>
            (await repository.getHistory()).firstOrNull?.title == 'Page A',
      );
      expect((await visitRows(db)).single.transition, PageTransition.link);
      expect(bloc.state.searchResults.map((h) => h.title), ['Page A']);
    });

    test('a quick second URL in the same tab is a redirect', () async {
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://short/'));
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://long/'));

      final [first, second] = await visitsWhen(2);
      expect(second.transition, PageTransition.redirect);
      expect(second.fromVisit, first.id);
      expect((await repository.getHistory()).map((h) => h.url), [
        'https://long/',
      ]);
    });

    test('a navigation the user starts is never a redirect', () async {
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://a/'));
      bloc.add(const BrowserUrlLoadRequested('https://b/'));
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://b/'));

      final [a, b] = await visitsWhen(2);
      expect(
        (a.transition, b.transition),
        (PageTransition.link, PageTransition.typed),
      );
      expect(b.fromVisit, isNull);
      expect((await urlRows(db)).last.typedCount, 1);
      expect(await repository.getHistory(), hasLength(2));
    });

    test('bookmarks, searches and reloads record their transition', () async {
      bloc.add(
        const BrowserUrlLoadRequested(
          'https://fav/',
          transition: PageTransition.autoBookmark,
        ),
      );
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://fav/'));
      await visitsWhen(1);

      bloc.add(const BrowserUrlLoadRequested('drift database'));
      await waitFor(() async => bloc.state.currentUrl.contains('drift'));
      bloc.add(BrowserUrlChanged(tabId: 't1', url: bloc.state.currentUrl));
      await visitsWhen(2);

      bloc.add(
        const BrowserUrlLoadRequested(
          'https://fav/',
          transition: PageTransition.reload,
        ),
      );
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://fav/'));

      expect((await visitsWhen(3)).map((v) => v.transition), [
        PageTransition.autoBookmark,
        PageTransition.generated,
        PageTransition.reload,
      ]);
    });

    test('the same URL reported twice is one visit', () async {
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://a/'));
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://a/'));
      await visitsWhen(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await visitRows(db), hasLength(1));
    });

    test('private tabs are not recorded', () async {
      bloc.add(const BrowserUrlChanged(tabId: 'p1', url: 'https://secret/'));
      bloc.add(const BrowserUrlChanged(tabId: 't1', url: 'https://a/'));
      await visitsWhen(1);
      expect((await repository.getHistory()).map((h) => h.url), ['https://a/']);
    });

    test('suggestions are one per URL, and can be deleted', () async {
      await repository.addVisit('https://a/', time: at(1));
      await repository.addVisit('https://a/', time: at(2));
      await repository.addVisit('https://ab/', time: at(3));

      bloc.add(const BrowserSearchQueryChanged('a'));
      await waitFor(() async => bloc.state.searchResults.isNotEmpty);
      expect(bloc.state.searchResults.map((h) => h.url), [
        'https://ab/',
        'https://a/',
      ]);

      bloc.add(BrowserHistoryItemDeleted(bloc.state.searchResults.first, 'a'));
      await waitFor(() async => bloc.state.searchResults.length == 1);
      expect(bloc.state.searchResults.single.url, 'https://a/');
      expect(await repository.getHistory(), hasLength(2));
    });
  });
}
