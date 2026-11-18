import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/tab_repository.dart';
import 'package:webview_cef/webview_cef.dart';

TabEntity entity(String tabId, int index, {bool active = false}) => TabEntity(
  tabId: tabId,
  tabIndex: index,
  url: 'https://$tabId.example/',
  title: tabId,
  isActive: active,
  screenshot: Uint8List.fromList([index, 1, 2]),
);

/// Counts writes and makes each one slow, so writes overlap with new tab
/// changes.
class SlowTabRepository extends TabRepository {
  SlowTabRepository(AppDatabase db) : super(db: db);

  int writes = 0;

  @override
  Future<void> replaceAllTabs(List<TabEntity> tabs) async {
    writes++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await super.replaceAllTabs(tabs);
  }
}

BrowserTab tab(String id) => BrowserTab(
  id: id,
  controller: WebViewController(const MethodChannel('test'), id.hashCode),
  currentUrl: '',
  title: id,
  isHomePage: true,
  isLoading: false,
  isPrivate: false,
);

/// A bloc with tabs `t1` (active) and `t2`, without BrowserInitialized
/// (which needs the app's storage services and CEF).
class SeededBrowserBloc extends BrowserBloc {
  SeededBrowserBloc(TabRepository tabs) : super(tabRepository: tabs) {
    emit(
      const BrowserState.initial().copyWith(
        isInitialized: true,
        normalTabs: [tab('t1'), tab('t2')],
        activeNormalTabIndex: 0,
      ),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('saves and restores tabs in tab order, with screenshots', () async {
    final repository = TabRepository(db: db);
    await repository.replaceAllTabs([
      entity('b', 1),
      entity('a', 0, active: true),
    ]);

    final tabs = await repository.getAllTabs();
    expect(tabs.map((t) => (t.tabId, t.tabIndex, t.isActive)), [
      ('a', 0, true),
      ('b', 1, false),
    ]);
    expect(tabs.first.screenshot, [0, 1, 2]);
    expect(tabs.first.url, 'https://a.example/');
  });

  test('replacing drops tabs that are gone', () async {
    final repository = TabRepository(db: db);
    await repository.replaceAllTabs([entity('a', 0), entity('b', 1)]);
    await repository.replaceAllTabs([entity('b', 0)]);
    expect((await repository.getAllTabs()).map((t) => t.tabId), ['b']);

    await repository.replaceAllTabs([]);
    expect(await repository.getAllTabs(), isEmpty);
  });

  test('rapid tab changes collapse into a few ordered writes', () async {
    final repository = SlowTabRepository(db);
    final bloc = SeededBrowserBloc(repository);
    // The bloc is not closed: close() shuts down CEF, which isn't running.

    for (var i = 1; i <= 10; i++) {
      bloc.add(
        BrowserUrlChanged(tabId: 't${i.isOdd ? 1 : 2}', url: 'https://$i/'),
      );
    }

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    List<TabEntity> saved = [];
    while (saved.length != 2 || saved[1].url != 'https://10/') {
      if (DateTime.now().isAfter(deadline)) fail('timed out: $saved');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      saved = await repository.getAllTabs();
    }

    expect(saved.map((t) => (t.tabId, t.url, t.isActive)), [
      ('t1', 'https://9/', true),
      ('t2', 'https://10/', false),
    ]);
    expect(repository.writes, lessThan(10));
  });
}
