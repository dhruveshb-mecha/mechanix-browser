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
  Future<void> saveTabs(List<TabEntity> tabs) async {
    writes++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await super.saveTabs(tabs);
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

  test('saves and restores tabs in tab order', () async {
    final repository = TabRepository(db: db);
    await repository.saveTabs([entity('b', 1), entity('a', 0, active: true)]);

    final tabs = await repository.getAllTabs();
    expect(tabs.map((t) => (t.tabId, t.tabIndex, t.isActive)), [
      ('a', 0, true),
      ('b', 1, false),
    ]);
    expect(tabs.first.url, 'https://a.example/');
  });

  test('screenshots are saved per tab and kept by later tab saves', () async {
    final repository = TabRepository(db: db);
    await repository.saveTabs([entity('a', 0), entity('b', 1)]);
    expect((await repository.getAllTabs()).map((t) => t.screenshot), [
      null,
      null,
    ], reason: 'saveTabs never writes screenshots');

    await repository.saveScreenshot('b', Uint8List.fromList([7, 7]));
    await repository.saveScreenshot('missing', Uint8List.fromList([1]));
    // Reorder and rename: the screenshot stays with its tab.
    final b = entity('b', 0)..title = 'renamed';
    await repository.saveTabs([b, entity('a', 1)]);

    final [first, second] = await repository.getAllTabs();
    expect((first.tabId, first.title), ('b', 'renamed'));
    expect(first.screenshot, [7, 7]);
    expect((second.tabId, second.screenshot), ('a', null));
  });

  test('saving drops tabs that are gone and keeps row ids', () async {
    final repository = TabRepository(db: db);
    await repository.saveTabs([entity('a', 0), entity('b', 1)]);
    final idOfB = (await repository.getAllTabs()).last.id;

    await repository.saveTabs([entity('b', 0)]);
    final [b] = await repository.getAllTabs();
    expect((b.tabId, b.id), ('b', idOfB), reason: 'updated, not re-inserted');

    await repository.saveTabs([]);
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
