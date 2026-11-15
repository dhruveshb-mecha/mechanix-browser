import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/presentation/shortcuts/browser_keyboard_shortcuts.dart';
import 'package:webview_cef/webview_cef.dart';

/// Records events instead of running them, with a seeded state.
class RecordingBrowserBloc extends BrowserBloc {
  final List<BrowserEvent> events = [];

  RecordingBrowserBloc(BrowserState seeded) {
    emit(seeded);
  }

  @override
  void add(BrowserEvent event) => events.add(event);
}

BrowserTab tab(String id, {bool home = false, bool private = false}) =>
    BrowserTab(
      id: id,
      controller: WebViewController(const MethodChannel('test'), id.hashCode),
      currentUrl: home ? '' : 'https://$id.example.com/',
      title: id,
      isHomePage: home,
      isLoading: false,
      isPrivate: private,
    );

BrowserState browserState({
  int tabCount = 3,
  int active = 0,
  BrowserMode mode = BrowserMode.normal,
  bool homePage = false,
}) {
  final tabs = [
    for (var i = 0; i < tabCount; i++)
      tab('t$i', home: homePage, private: mode == BrowserMode.private),
  ];
  final normal = mode == BrowserMode.normal;
  return const BrowserState.initial().copyWith(
    isInitialized: true,
    normalTabs: normal ? tabs : const [],
    privateTabs: normal ? const [] : tabs,
    activeNormalTabIndex: normal ? active : 0,
    activePrivateTabIndex: normal ? 0 : active,
    mode: mode,
  );
}

void main() {
  late RecordingBrowserBloc bloc;
  late FocusNode addressBar;
  late FocusNode webview;
  late List<KeyEvent> pageKeys;

  Future<void> pumpBrowser(WidgetTester tester, BrowserState state) async {
    bloc = RecordingBrowserBloc(state);
    addressBar = FocusNode(debugLabel: 'addressBar');
    webview = FocusNode(debugLabel: 'webview');
    pageKeys = [];
    // The bloc is not closed: BrowserBloc.close() tears down native webviews,
    // which do not exist in these tests.
    addTearDown(() {
      addressBar.dispose();
      webview.dispose();
    });

    await tester.pumpWidget(
      BlocProvider<BrowserBloc>.value(
        value: bloc,
        child: MaterialApp(
          routes: {
            '/': (_) => BrowserKeyboardShortcuts(
              addressBarFocusNode: addressBar,
              child: Scaffold(
                body: Column(
                  children: [
                    TextField(focusNode: addressBar),
                    // Stands in for the CEF webview, which claims every key.
                    Focus(
                      focusNode: webview,
                      autofocus: true,
                      onKeyEvent: (node, event) {
                        pageKeys.add(event);
                        return KeyEventResult.handled;
                      },
                      child: const SizedBox(width: 100, height: 100),
                    ),
                  ],
                ),
              ),
            ),
            '/history': (_) => const Scaffold(body: Text('History screen')),
          },
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool control = false,
    bool shift = false,
    bool alt = false,
  }) async {
    final modifiers = [
      if (control) LogicalKeyboardKey.controlLeft,
      if (shift) LogicalKeyboardKey.shiftLeft,
      if (alt) LogicalKeyboardKey.altLeft,
    ];
    for (final m in modifiers) {
      await tester.sendKeyDownEvent(m);
    }
    await tester.sendKeyEvent(key);
    for (final m in modifiers.reversed) {
      await tester.sendKeyUpEvent(m);
    }
    await tester.pump();
  }

  bool pageGotKeyDown(LogicalKeyboardKey key) =>
      pageKeys.any((e) => e is KeyDownEvent && e.logicalKey == key);

  testWidgets('Ctrl+T opens a tab and never reaches the page', (tester) async {
    await pumpBrowser(tester, browserState());
    await press(tester, LogicalKeyboardKey.keyT, control: true);

    expect(
      bloc.events.single,
      isA<BrowserNewTabRequested>().having(
        (e) => e.isPrivate,
        'isPrivate',
        false,
      ),
    );
    expect(pageGotKeyDown(LogicalKeyboardKey.keyT), isFalse);
  });

  testWidgets('keys that are not shortcuts still reach the page', (
    tester,
  ) async {
    await pumpBrowser(tester, browserState());
    await press(tester, LogicalKeyboardKey.keyT);
    await press(tester, LogicalKeyboardKey.keyC, control: true);
    await press(tester, LogicalKeyboardKey.escape);

    expect(bloc.events, isEmpty);
    expect(pageGotKeyDown(LogicalKeyboardKey.keyT), isTrue);
    expect(pageGotKeyDown(LogicalKeyboardKey.keyC), isTrue);
    expect(pageGotKeyDown(LogicalKeyboardKey.escape), isTrue);
  });

  testWidgets('Ctrl+T in private mode opens a private tab', (tester) async {
    await pumpBrowser(tester, browserState(mode: BrowserMode.private));
    await press(tester, LogicalKeyboardKey.keyT, control: true);
    expect((bloc.events.single as BrowserNewTabRequested).isPrivate, isTrue);
  });

  testWidgets('Ctrl+Shift+N opens a private tab', (tester) async {
    await pumpBrowser(tester, browserState());
    await press(tester, LogicalKeyboardKey.keyN, control: true, shift: true);
    expect((bloc.events.single as BrowserNewTabRequested).isPrivate, isTrue);
  });

  testWidgets('Ctrl+W closes the active tab', (tester) async {
    await pumpBrowser(tester, browserState(active: 1));
    await press(tester, LogicalKeyboardKey.keyW, control: true);
    expect((bloc.events.single as BrowserCloseTabRequested).tabId, 't1');
  });

  group('tab switching', () {
    String switchedTo() =>
        (bloc.events.single as BrowserSwitchTabRequested).tabId;

    testWidgets('Ctrl+Tab goes to the next tab', (tester) async {
      await pumpBrowser(tester, browserState(active: 0));
      await press(tester, LogicalKeyboardKey.tab, control: true);
      expect(switchedTo(), 't1');
    });

    testWidgets('Ctrl+Shift+Tab wraps to the last tab', (tester) async {
      await pumpBrowser(tester, browserState(active: 0));
      await press(tester, LogicalKeyboardKey.tab, control: true, shift: true);
      expect(switchedTo(), 't2');
    });

    testWidgets('Ctrl+2 selects the second tab', (tester) async {
      await pumpBrowser(tester, browserState(active: 0));
      await press(tester, LogicalKeyboardKey.digit2, control: true);
      expect(switchedTo(), 't1');
    });

    testWidgets('Ctrl+9 selects the last tab', (tester) async {
      await pumpBrowser(tester, browserState(active: 0));
      await press(tester, LogicalKeyboardKey.digit9, control: true);
      expect(switchedTo(), 't2');
    });

    testWidgets('Ctrl+5 with three tabs does nothing', (tester) async {
      await pumpBrowser(tester, browserState(active: 0));
      await press(tester, LogicalKeyboardKey.digit5, control: true);
      expect(bloc.events, isEmpty);
      expect(pageGotKeyDown(LogicalKeyboardKey.digit5), isFalse);
    });
  });

  testWidgets('navigation shortcuts', (tester) async {
    await pumpBrowser(tester, browserState());
    await press(tester, LogicalKeyboardKey.arrowLeft, alt: true);
    await press(tester, LogicalKeyboardKey.arrowRight, alt: true);
    await press(tester, LogicalKeyboardKey.keyR, control: true);
    await press(tester, LogicalKeyboardKey.f5);
    await press(tester, LogicalKeyboardKey.home, alt: true);
    await press(tester, LogicalKeyboardKey.f12);

    expect(bloc.events.map((e) => e.runtimeType), [
      BrowserGoBackRequested,
      BrowserGoForwardRequested,
      BrowserReloadRequested,
      BrowserReloadRequested,
      BrowserGoHomeRequested,
      BrowserDevToolsRequested,
    ]);
  });

  testWidgets('Ctrl+D bookmarks the current page', (tester) async {
    await pumpBrowser(tester, browserState(active: 2));
    await press(tester, LogicalKeyboardKey.keyD, control: true);
    final event = bloc.events.single as BrowserBookmarkToggled;
    expect(event.url, 'https://t2.example.com/');
    expect(event.title, 't2');
  });

  testWidgets('Ctrl+L focuses the address bar, Escape leaves it', (
    tester,
  ) async {
    await pumpBrowser(tester, browserState());
    await press(tester, LogicalKeyboardKey.keyL, control: true);
    expect(addressBar.hasFocus, isTrue);
    expect(
      bloc.events.single,
      isA<BrowserBottomBarVisibilityChanged>().having(
        (e) => e.isVisible,
        'isVisible',
        true,
      ),
    );

    // Editing shortcuts are left to the text field.
    await press(tester, LogicalKeyboardKey.keyA, control: true);
    expect(addressBar.hasFocus, isTrue);
    expect(bloc.events, hasLength(1));

    await press(tester, LogicalKeyboardKey.escape);
    expect(addressBar.hasFocus, isFalse);
    expect(pageGotKeyDown(LogicalKeyboardKey.escape), isFalse);
  });

  testWidgets('Ctrl+H opens history and hides the webview meanwhile', (
    tester,
  ) async {
    await pumpBrowser(tester, browserState());
    await press(tester, LogicalKeyboardKey.keyH, control: true);
    await tester.pumpAndSettle();

    expect(find.text('History screen'), findsOneWidget);
    expect((bloc.events.single as BrowserWasHiddenRequested).isHidden, isTrue);

    // Shortcuts are off while another screen is on top.
    await press(tester, LogicalKeyboardKey.keyT, control: true);
    expect(bloc.events, hasLength(1));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect((bloc.events.last as BrowserWasHiddenRequested).isHidden, isFalse);
  });

  testWidgets('shortcuts are off while a dialog is open', (tester) async {
    await pumpBrowser(tester, browserState());
    showDialog<void>(
      context: tester.element(find.byType(Scaffold)),
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.keyW, control: true);
    expect(bloc.events, isEmpty);
  });
}
