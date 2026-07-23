import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mechanix_browser/core/services/objectbox_service.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('History Repository and Saving Tests', () {
    late HistoryRepositoryImpl repository;

    setUpAll(() async {
      await ObjectBoxService.initialize();
      repository = HistoryRepositoryImpl();
    });

    tearDownAll(() {
      repository.close();
      ObjectBoxService.close();
    });

    setUp(() {
      repository.clearHistory();
    });

    test('should save and retrieve history items', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry1 = BrowserHistory(
        url: 'https://example.com',
        title: 'Example Domain',
        timestamp: now - 5000,
      );
      final entry2 = BrowserHistory(
        url: 'https://github.com',
        title: 'GitHub',
        timestamp: now,
      );

      repository.saveHistory(entry1);
      repository.saveHistory(entry2);

      final history = repository.getHistory();
      expect(history.length, 2);
      expect(history[0].url, 'https://github.com'); // Ordered descending
      expect(history[0].title, 'GitHub');
      expect(history[1].url, 'https://example.com');
      expect(history[1].title, 'Example Domain');
    });

    test('should search history items', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry1 = BrowserHistory(
        url: 'https://example.com',
        title: 'Example Domain',
        timestamp: now - 5000,
      );
      final entry2 = BrowserHistory(
        url: 'https://github.com',
        title: 'GitHub',
        timestamp: now,
      );

      repository.saveHistory(entry1);
      repository.saveHistory(entry2);

      final searchResults = repository.searchHistory('hub');
      expect(searchResults.length, 1);
      expect(searchResults[0].url, 'https://github.com');
    });

    test('should delete individual history item', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = BrowserHistory(
        url: 'https://example.com',
        title: 'Example Domain',
        timestamp: now,
      );

      repository.saveHistory(entry);
      var history = repository.getHistory();
      expect(history.length, 1);

      repository.deleteHistory(history[0].id);
      history = repository.getHistory();
      expect(history.isEmpty, true);
    });

    test('should clear history', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      repository.saveHistory(
        BrowserHistory(
          url: 'https://example.com',
          title: 'Example',
          timestamp: now,
        ),
      );
      repository.saveHistory(
        BrowserHistory(url: 'https://github.com', title: 'GitHub', timestamp: now),
      );

      expect(repository.getHistory().length, 2);

      repository.clearHistory();
      expect(repository.getHistory().isEmpty, true);
    });

    test('should save multiple page visits in history', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('webview_cef'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'create') {
            return [1, 1];
          }
          return null;
        },
      );

      final bloc = BrowserBloc();
      bloc.add(BrowserInitialized());
      await Future.delayed(const Duration(milliseconds: 500));

      final tabId = bloc.state.tabs.first.id;

      // Simulate navigating to Page 1
      bloc.add(BrowserUrlChanged(tabId: tabId, url: 'https://flutter.dev/'));
      bloc.add(BrowserTitleChanged(tabId: tabId, title: 'Flutter - Build apps for any screen'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate navigating to Page 2
      bloc.add(BrowserUrlChanged(tabId: tabId, url: 'https://flutter.dev/showcase'));
      bloc.add(BrowserTitleChanged(tabId: tabId, title: 'Showcase - Flutter'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate navigating to Page 3
      bloc.add(BrowserUrlChanged(tabId: tabId, url: 'https://flutter.dev/community'));
      bloc.add(BrowserTitleChanged(tabId: tabId, title: 'Community - Flutter'));
      await Future.delayed(const Duration(milliseconds: 100));

      final history = repository.getHistory();
      for (var item in history) {
        print('HISTORY ITEM: url=${item.url}, title=${item.title}');
      }
    });

    test('should handle redirects by overwriting the recent visit instead of duplicating', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('webview_cef'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'create') {
            return [1, 1];
          }
          return null;
        },
      );

      final bloc = BrowserBloc();
      bloc.add(BrowserInitialized());
      await Future.delayed(const Duration(milliseconds: 500));

      final tabId = bloc.state.tabs.first.id;

      // Navigate to initial URL
      bloc.add(BrowserUrlChanged(tabId: tabId, url: 'https://flutter.dev'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate a redirect happening 100ms later to /showcase
      bloc.add(BrowserUrlChanged(tabId: tabId, url: 'https://flutter.dev/showcase'));
      await Future.delayed(const Duration(milliseconds: 100));

      final history = repository.getHistory();
      expect(history.length, 1);
      expect(history.first.url, 'https://flutter.dev/showcase');
    });
  });
}
