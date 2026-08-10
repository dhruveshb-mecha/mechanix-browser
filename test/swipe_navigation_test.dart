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
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Swipe Navigation Tests', () {
    bool canGoBackResult = false;
    bool canGoForwardResult = false;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('webview_cef'), (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'create') {
              return [1, 1]; // browserId, textureId
            } else if (methodCall.method == 'canGoBack') {
              return canGoBackResult;
            } else if (methodCall.method == 'canGoForward') {
              return canGoForwardResult;
            }
            return null;
          });
    });

    Future<void> initializeWebviewManager(WidgetTester tester) async {
      final initFuture = WebviewManager().initialize();
      await tester.pump(const Duration(milliseconds: 500));
      await initFuture;
    }

    testWidgets('Swipe Right (Back) should navigate if canGoBack is true', (
      WidgetTester tester,
    ) async {
      canGoBackResult = true;
      canGoForwardResult = false;

      await initializeWebviewManager(tester);

      final controller = WebviewManager().createWebView();
      final initControllerFuture = controller.initialize('https://example.com');
      await tester.pump(const Duration(milliseconds: 100));
      await initControllerFuture;

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

      // Perform a swipe right gesture (touch down, drag right, touch up)
      final gesture = await tester.startGesture(
        const Offset(50, 200),
        pointer: 1,
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(150, 0));
      await gesture.up();

      // Wait for async calls to resolve
      await tester.pumpAndSettle();

      expect(fakeBloc.addedEvents, contains(isA<BrowserGoBackRequested>()));
    });

    testWidgets(
      'Swipe Right (Back) should NOT navigate if canGoBack is false',
      (WidgetTester tester) async {
        canGoBackResult = false;
        canGoForwardResult = false;

        await initializeWebviewManager(tester);

        final controller = WebviewManager().createWebView();
        final initControllerFuture = controller.initialize(
          'https://example.com',
        );
        await tester.pump(const Duration(milliseconds: 100));
        await initControllerFuture;

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
            home: Scaffold(
              body: BrowserGestureNavigator(
                tab: tab,
                bloc: fakeBloc,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(150, 0));
        await gesture.up();

        await tester.pumpAndSettle();

        expect(
          fakeBloc.addedEvents,
          isNot(contains(isA<BrowserGoBackRequested>())),
        );
      },
    );

    testWidgets(
      'Swipe Left (Forward) should navigate if canGoForward is true',
      (WidgetTester tester) async {
        canGoBackResult = false;
        canGoForwardResult = true;

        await initializeWebviewManager(tester);

        final controller = WebviewManager().createWebView();
        final initControllerFuture = controller.initialize(
          'https://example.com',
        );
        await tester.pump(const Duration(milliseconds: 100));
        await initControllerFuture;

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
            home: Scaffold(
              body: BrowserGestureNavigator(
                tab: tab,
                bloc: fakeBloc,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        // Perform a swipe left gesture (touch down, drag left, touch up)
        final gesture = await tester.startGesture(
          const Offset(200, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(-150, 0));
        await gesture.up();

        await tester.pumpAndSettle();

        expect(
          fakeBloc.addedEvents,
          contains(isA<BrowserGoForwardRequested>()),
        );
      },
    );

    testWidgets(
      'Swipe below threshold should NOT navigate and should spring back to zero',
      (WidgetTester tester) async {
        canGoBackResult = true;
        canGoForwardResult = false;

        await initializeWebviewManager(tester);

        final controller = WebviewManager().createWebView();
        final initControllerFuture = controller.initialize(
          'https://example.com',
        );
        await tester.pump(const Duration(milliseconds: 100));
        await initControllerFuture;

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
            home: Scaffold(
              body: BrowserGestureNavigator(
                tab: tab,
                bloc: fakeBloc,
                child: const ContainerKeyWidget(key: Key('content')),
              ),
            ),
          ),
        );

        // Perform swipe below threshold (50px < 150px)
        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();

        // Check caret indicator during drag
        final indicatorFinder = find.byKey(
          const Key('swipe_caret_indicator'),
        );
        expect(indicatorFinder, findsOneWidget);

        // Release drag
        await gesture.up();
        await tester.pumpAndSettle();

        // Ensure no navigation occurred
        expect(
          fakeBloc.addedEvents,
          isNot(contains(isA<BrowserGoBackRequested>())),
        );

        // Ensure indicator animated away
        expect(indicatorFinder, findsNothing);
      },
    );

    testWidgets(
      'Swipe indicator should show caret indicator and navigate when threshold reached',
      (WidgetTester tester) async {
        canGoBackResult = true;
        canGoForwardResult = false;

        await initializeWebviewManager(tester);

        final controller = WebviewManager().createWebView();
        final initControllerFuture = controller.initialize(
          'https://example.com',
        );
        await tester.pump(const Duration(milliseconds: 100));
        await initControllerFuture;

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
            home: Scaffold(
              body: BrowserGestureNavigator(
                tab: tab,
                bloc: fakeBloc,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        // Drag large distance (300px >= threshold 150px)
        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(300, 0));
        await tester.pump();

        final indicatorFinder = find.byKey(
          const Key('swipe_caret_indicator'),
        );
        expect(indicatorFinder, findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(fakeBloc.addedEvents, contains(isA<BrowserGoBackRequested>()));
      },
    );

    testWidgets(
      'Swipe when navigation unavailable should display disabled indicator and not navigate',
      (WidgetTester tester) async {
        canGoBackResult = false;
        canGoForwardResult = false;

        await initializeWebviewManager(tester);

        final controller = WebviewManager().createWebView();
        final initControllerFuture = controller.initialize(
          'https://example.com',
        );
        await tester.pump(const Duration(milliseconds: 100));
        await initControllerFuture;

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
            home: Scaffold(
              body: BrowserGestureNavigator(
                tab: tab,
                bloc: fakeBloc,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(300, 0));
        await tester.pump();

        final indicatorFinder = find.byKey(
          const Key('swipe_caret_indicator'),
        );
        expect(indicatorFinder, findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(
          fakeBloc.addedEvents,
          isNot(contains(isA<BrowserGoBackRequested>())),
        );
      },
    );

    group('Mouse interaction protection', () {
      testWidgets('Swipe Right with mouse pointer should NOT navigate', (
        WidgetTester tester,
      ) async {
        canGoBackResult = true;
        canGoForwardResult = false;

        await initializeWebviewManager(tester);

        final controller = WebviewManager().createWebView();
        final initControllerFuture = controller.initialize(
          'https://example.com',
        );
        await tester.pump(const Duration(milliseconds: 100));
        await initControllerFuture;

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
            home: Scaffold(
              body: BrowserGestureNavigator(
                tab: tab,
                bloc: fakeBloc,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        // Simulate a mouse drag (PointerDeviceKind.mouse)
        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(150, 0));
        await gesture.up();

        await tester.pumpAndSettle();

        expect(
          fakeBloc.addedEvents,
          isNot(contains(isA<BrowserGoBackRequested>())),
        );
      });
    });
  });
}

class ContainerKeyWidget extends StatelessWidget {
  const ContainerKeyWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
