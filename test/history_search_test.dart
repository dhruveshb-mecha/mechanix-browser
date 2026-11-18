import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/history/history_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/bookmarks_screen.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/history_screen.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

DateTime at(int minutes) =>
    DateTime.utc(2026, 1, 1).add(Duration(minutes: minutes));

Future<void> waitFor(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// A bloc without BrowserInitialized (which needs the app's storage
/// services and CEF).
class SeededBrowserBloc extends BrowserBloc {
  SeededBrowserBloc(BrowserState seeded, {super.historyRepository}) {
    emit(seeded);
  }
}

Widget app(Widget home, List<BlocProvider> providers) => MultiBlocProvider(
  providers: providers,
  child: MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  late AppDatabase db;
  late HistoryRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = HistoryRepositoryImpl(db: db);
  });
  tearDown(() => db.close());

  group('repository paging and search', () {
    test('pages cover every visit once, even with equal times', () async {
      // 7 visits, several sharing a timestamp.
      for (final (url, minute) in [
        ('a', 1),
        ('b', 2),
        ('c', 2),
        ('d', 2),
        ('e', 3),
        ('f', 4),
        ('g', 4),
      ]) {
        await repository.addVisit('https://$url/', time: at(minute));
      }

      final seen = <BrowserHistory>[];
      BrowserHistory? after;
      while (true) {
        final page = await repository.getHistory(limit: 3, after: after);
        if (page.isEmpty) break;
        seen.addAll(page);
        after = page.last;
      }
      expect(seen.map((h) => h.id).toSet(), hasLength(7));
      expect(seen.map((h) => h.id), [
        for (final h in await repository.getHistory()) h.id,
      ], reason: 'same order');
    });

    test('search matches the stored title and pages too', () async {
      for (var i = 0; i < 5; i++) {
        await repository.addVisit('https://docs.example/$i', time: at(i));
      }
      await repository.addVisit('https://other.example/', time: at(9));
      await repository.setTitle('https://other.example/', 'Flutter Docs');

      final first = await repository.searchHistory('docs', limit: 4);
      expect(first.first.url, 'https://other.example/', reason: 'by title');
      final rest = await repository.searchHistory(
        'docs',
        limit: 4,
        after: first.last,
      );
      expect([...first, ...rest].map((h) => h.url).toSet(), hasLength(6));
    });
  });

  group('HistoryBloc', () {
    late HistoryBloc bloc;
    setUp(() => bloc = HistoryBloc(repository: repository));
    tearDown(() => bloc.close());

    Future<void> addVisits(int count, {String prefix = 'p'}) async {
      for (var i = 0; i < count; i++) {
        await repository.addVisit('https://$prefix$i/', time: at(i));
      }
    }

    test('loads a page at a time', () async {
      const pageSize = AppConstants.historyPageSize;
      await addVisits(pageSize + 10);

      bloc.add(const HistoryLoadRequested());
      await waitFor(() => bloc.state.historyItems.isNotEmpty);
      expect(bloc.state.historyItems, hasLength(pageSize));
      expect(bloc.state.hasMore, isTrue);

      bloc.add(const HistoryLoadMoreRequested());
      await waitFor(() => bloc.state.historyItems.length > pageSize);
      expect(bloc.state.historyItems, hasLength(pageSize + 10));
      expect(bloc.state.hasMore, isFalse);
      expect(bloc.state.historyItems.first.url, 'https://p${pageSize + 9}/');
    });

    test('search filters, and reopening the screen shows everything', () async {
      await addVisits(3);
      await addVisits(2, prefix: 'needle');

      bloc.add(const HistorySearchQueryChanged(' needle '));
      await waitFor(() => bloc.state.searchQuery == 'needle');
      expect(bloc.state.historyItems.map((h) => h.url), [
        'https://needle1/',
        'https://needle0/',
      ]);

      bloc.add(const HistoryLoadRequested());
      await waitFor(() => bloc.state.historyItems.length == 5);
      expect(bloc.state.searchQuery, '');
    });
  });

  test('address-bar suggestions are capped', () async {
    for (var i = 0; i < 30; i++) {
      await repository.addVisit('https://site$i.example/', time: at(i));
    }
    final bloc = SeededBrowserBloc(
      const BrowserState.initial().copyWith(isInitialized: true),
      historyRepository: repository,
    );
    // Not closed: close() shuts down CEF, which isn't running.

    bloc.add(const BrowserSearchQueryChanged(''));
    await waitFor(() => bloc.state.searchResults.isNotEmpty);
    expect(
      bloc.state.searchResults,
      hasLength(AppConstants.maxHistorySuggestions),
    );

    bloc.add(const BrowserSearchQueryChanged('site'));
    await waitFor(
      () => bloc.state.searchResults.first.url == 'https://site29.example/',
    );
    expect(
      bloc.state.searchResults,
      hasLength(AppConstants.maxHistorySuggestions),
    );
  });

  test('Bookmark.matches checks title and URL, ignoring case', () {
    final b = Bookmark.create(
      url: 'https://flutter.dev/docs',
      title: 'Flutter Docs',
      timestamp: 0,
      type: BookmarkType.bookmark,
    );
    expect(b.matches(''), isTrue);
    expect(b.matches('FLUTTER'), isTrue);
    expect(b.matches('dev/doc'), isTrue);
    expect(b.matches('docs '), isTrue);
    expect(b.matches('dart'), isFalse);
  });

  group('screens', () {
    setUp(() {
      // The bookmarks screen's webview-free parts only; nothing calls CEF.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('webview_cef'),
            (_) async => null,
          );
    });

    testWidgets('typing in the history search filters the list', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await repository.addVisit('https://apple.example/', time: at(1));
        await repository.addVisit('https://banana.example/', time: at(2));
      });
      final bloc = HistoryBloc(repository: repository);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        app(const HistoryScreen(), [
          BlocProvider<HistoryBloc>.value(value: bloc),
        ]),
      );
      await tester.runAsync(
        () => waitFor(() => bloc.state.historyItems.length == 2),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('banana', findRichText: true), findsWidgets);

      await tester.enterText(find.byType(TextField), 'apple');
      await tester.runAsync(
        () => waitFor(() => bloc.state.historyItems.length == 1),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('banana', findRichText: true), findsNothing);
      expect(find.textContaining('apple', findRichText: true), findsWidgets);

      await tester.enterText(find.byType(TextField), 'cherry');
      await tester.runAsync(
        () => waitFor(() => bloc.state.historyItems.isEmpty),
      );
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('typing in the bookmarks search filters both lists', (
      tester,
    ) async {
      Bookmark mk(int id, String url, String title, BookmarkType type) =>
          Bookmark.create(
            id: id,
            url: url,
            title: title,
            timestamp: 0,
            type: type,
          );
      final bloc = SeededBrowserBloc(
        const BrowserState.initial().copyWith(
          isInitialized: true,
          favorites: [
            mk(1, 'https://fav-apple/', 'Fav Apple', BookmarkType.favorite),
          ],
          bookmarks: [
            mk(2, 'https://apple-pie/', 'Apple Pie', BookmarkType.bookmark),
            mk(3, 'https://banana/', 'Banana Bread', BookmarkType.bookmark),
          ],
        ),
      );

      await tester.pumpWidget(
        app(const BookmarksScreen(), [
          BlocProvider<BrowserBloc>.value(value: bloc),
        ]),
      );
      expect(find.text('Banana Bread'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pump();
      expect(find.text('Banana Bread'), findsNothing);
      expect(find.text('Apple Pie'), findsOneWidget);
      expect(find.text('Fav Apple'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'banana');
      await tester.pump();
      expect(find.text('Fav Apple'), findsNothing);
      expect(find.text('No matches'), findsOneWidget, reason: 'no favorite');
    });
  });
}
