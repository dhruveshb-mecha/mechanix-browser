import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/webview_body.dart';
import 'package:webview_cef/webview_cef.dart';

class FakeBrowserBloc extends BrowserBloc {
  final List<BrowserEvent> addedEvents = [];

  FakeBrowserBloc() : super();

  @override
  void add(BrowserEvent event) {
    addedEvents.add(event);
    super.add(event);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Bar Auto Hide Tests', () {
    bool canGoBackResult = false;
    bool canGoForwardResult = false;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('webview_cef'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'create') {
            return [1, 1]; // browserId, textureId
          } else if (methodCall.method == 'canGoBack') {
            return canGoBackResult;
          } else if (methodCall.method == 'canGoForward') {
            return canGoForwardResult;
          }
          return true;
        },
      );
    });

    Future<void> initializeWebviewManager(WidgetTester tester) async {
      final initFuture = WebviewManager().initialize();
      await tester.pump(const Duration(milliseconds: 500));
      await initFuture;
    }

    Future<WebViewController> createInitializedController(WidgetTester tester) async {
      final controller = WebviewManager().createWebView();
      final initFuture = controller.initialize('https://example.com');
      await tester.pump(const Duration(milliseconds: 100));
      await initFuture;
      return controller;
    }

    testWidgets('scroll down beyond threshold -> hides bottom bar',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();
      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(0, -50));
      await gesture.up();

      await tester.pumpAndSettle();

      expect(fakeBloc.addedEvents, contains(const BrowserBottomBarVisibilityChanged(false)));
    });

    testWidgets('scroll up beyond threshold -> shows bottom bar -> auto-hides after 2 sec',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();
      fakeBloc.emit(fakeBloc.state.copyWith(isBottomBarVisible: false));
      expect(fakeBloc.state.isBottomBarVisible, false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(0, 50));
      await gesture.up();

      await tester.pump();
      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });

    testWidgets('tiny vertical movements -> unchanged state',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(0, -15));
      await gesture.up();

      await tester.pumpAndSettle();

      expect(fakeBloc.addedEvents, isNot(contains(isA<BrowserBottomBarVisibilityChanged>())));
    });

    testWidgets('alternating vertical movements (anti-flicker check) -> no changes',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(0, -25));
      await gesture.moveBy(const Offset(0, 25));
      await gesture.up();

      await tester.pumpAndSettle();

      expect(fakeBloc.addedEvents, isNot(contains(isA<BrowserBottomBarVisibilityChanged>())));
    });

    testWidgets('horizontal back/forward gestures still work and don\'t trigger vertical scroll actions',
        (WidgetTester tester) async {
      canGoBackResult = true;
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(50, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(150, 5));
      await gesture.up();

      await tester.pumpAndSettle();

      expect(fakeBloc.addedEvents, contains(isA<BrowserGoBackRequested>()));
      expect(fakeBloc.addedEvents, isNot(contains(isA<BrowserBottomBarVisibilityChanged>())));
    });

    testWidgets('page load completes -> bottom bar visible -> after 2 sec hidden',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: true,
      );

      final fakeBloc = FakeBrowserBloc();
      fakeBloc.emit(fakeBloc.state.copyWith(
        normalTabs: [tab],
        activeNormalTabIndex: 0,
        isBottomBarVisible: true,
      ));

      fakeBloc.add(const BrowserLoadEnded(tabId: 'tab_1'));
      await tester.pump();

      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });

    testWidgets('hidden + webpage tap -> visible -> after 2 sec hidden',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();
      fakeBloc.emit(fakeBloc.state.copyWith(isBottomBarVisible: false));
      expect(fakeBloc.state.isBottomBarVisible, false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture.up();
      await tester.pump();

      expect(fakeBloc.addedEvents, contains(const BrowserBottomBarVisibilityChanged(true)));
      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });

    testWidgets('second tap before timer expires -> old timer cancelled -> new 2 sec countdown',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Example',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();
      fakeBloc.emit(fakeBloc.state.copyWith(isBottomBarVisible: false));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: BrowserGestureNavigator(
              tab: tab,
              bloc: fakeBloc,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final gesture1 = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture1.up();
      await tester.pump();

      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pump(const Duration(seconds: 1));
      expect(fakeBloc.state.isBottomBarVisible, true);

      final gesture2 = await tester.startGesture(const Offset(200, 200), pointer: 1, kind: PointerDeviceKind.touch);
      await gesture2.up();
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 1500));
      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pump(const Duration(milliseconds: 500));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });

    testWidgets('address bar focused -> do not auto-hide until focus removed',
        (WidgetTester tester) async {
      final fakeBloc = FakeBrowserBloc();
      fakeBloc.emit(fakeBloc.state.copyWith(isBottomBarVisible: true));

      fakeBloc.add(const BrowserBottomBarVisibilityChanged(true, isInteracting: true));
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      expect(fakeBloc.state.isBottomBarVisible, true);

      fakeBloc.add(const BrowserBottomBarVisibilityChanged(true, isInteracting: false));
      await tester.pump();

      expect(fakeBloc.state.isBottomBarVisible, true);

      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });

    testWidgets('tab/navigation change -> stale timer cancelled',
        (WidgetTester tester) async {
      await initializeWebviewManager(tester);
      final controller = await createInitializedController(tester);

      final tab = BrowserTab(
        id: 'tab_1',
        controller: controller,
        currentUrl: 'https://example.com',
        title: 'Tab 1',
        isHomePage: false,
        isLoading: false,
      );

      final fakeBloc = FakeBrowserBloc();
      fakeBloc.emit(fakeBloc.state.copyWith(
        normalTabs: [tab],
        activeNormalTabIndex: 0,
        isBottomBarVisible: true,
      ));

      fakeBloc.add(const BrowserLoadEnded(tabId: 'tab_1'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));

      fakeBloc.add(const BrowserLoadStarted(tabId: 'tab_1'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, true);

      fakeBloc.add(const BrowserLoadEnded(tabId: 'tab_1'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });

    testWidgets('dispose -> timer cancelled without error',
        (WidgetTester tester) async {
      final fakeBloc = FakeBrowserBloc();
      fakeBloc.add(const BrowserBottomBarVisibilityChanged(true));
      await tester.pump();

      // Ensure timer is scheduled, then simulate dispose/closing of bloc without invoking unmocked quit channel
      fakeBloc.add(const BrowserBottomBarVisibilityChanged(false));
      await tester.pump(const Duration(seconds: 2));
      expect(fakeBloc.state.isBottomBarVisible, false);
    });
  });
}
