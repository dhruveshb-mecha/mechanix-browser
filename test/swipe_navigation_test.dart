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

        // Perform swipe below threshold (50px < 100px)
        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();

        // Check translation during drag (50 * 0.35 = 17.5px)
        final transformFinder = find.byKey(
          const Key('gesture_navigator_transform'),
        );
        expect(transformFinder, findsOneWidget);
        final transform = tester.widget<Transform>(transformFinder);
        expect(transform.transform.getTranslation().x, closeTo(17.5, 0.1));

        // Release drag
        await gesture.up();
        await tester.pumpAndSettle();

        // Ensure no navigation occurred
        expect(
          fakeBloc.addedEvents,
          isNot(contains(isA<BrowserGoBackRequested>())),
        );

        // Ensure translation animated back to 0.0
        final finalTransform = tester.widget<Transform>(transformFinder);
        expect(finalTransform.transform.getTranslation().x, equals(0.0));
      },
    );

    testWidgets(
      'Swipe translation should be clamped to maximum limit when navigation available',
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

        // Drag large distance (300px * 0.35 = 105px > max 80px)
        final gesture = await tester.startGesture(
          const Offset(50, 200),
          pointer: 1,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(300, 0));
        await tester.pump();

        final transform = tester.widget<Transform>(
          find.byKey(const Key('gesture_navigator_transform')),
        );
        expect(transform.transform.getTranslation().x, equals(80.0));

        await gesture.up();
        await tester.pumpAndSettle();

        expect(fakeBloc.addedEvents, contains(isA<BrowserGoBackRequested>()));
      },
    );

    testWidgets(
      'Swipe when navigation unavailable should restrict translation and spring back',
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

        // With unavailable resistance (0.05) and clamp (12.0), translation for 300px drag (300 * 0.05 = 15.0) should be clamped to 12.0
        final transform = tester.widget<Transform>(
          find.byKey(const Key('gesture_navigator_transform')),
        );
        expect(transform.transform.getTranslation().x, equals(12.0));

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
