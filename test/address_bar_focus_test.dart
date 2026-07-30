import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:webview_cef/webview_cef.dart';
import 'package:flutter/services.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

BrowserTab _tab({
  required String url,
  required String title,
  bool isHomePage = false,
  String id = 'tab_1',
}) {
  final controller = WebviewManager().createWebView();
  return BrowserTab(
    id: id,
    controller: controller,
    currentUrl: url,
    title: title,
    isHomePage: isHomePage,
    isLoading: false,
  );
}

BrowserState _stateWith(BrowserTab tab) =>
    const BrowserState.initial().copyWith(
      isInitialized: true,
      normalTabs: [tab],
      activeNormalTabIndex: 0,
    );

BrowserState _stateWithTabs(
  List<BrowserTab> tabs, {
  int activeIndex = 0,
}) =>
    const BrowserState.initial().copyWith(
      isInitialized: true,
      normalTabs: tabs,
      activeNormalTabIndex: activeIndex,
    );

// ── Unit: Address bar display logic ──────────────────────────────────────────

/// Simulates the text-controller update logic of _BrowserBottomBarState.
/// Returns what the address bar should display.
String addressBarDisplayText({
  required bool hasFocus,
  required BrowserState state,
}) {
  if (hasFocus) {
    return state.isHomePage ? '' : state.currentUrl;
  } else {
    if (state.isHomePage) return '';
    return state.title.isNotEmpty ? state.title : state.currentUrl;
  }
}

/// Simulates the "is user input protected" logic.
///
/// When the field is focused, only update the text if the current controller
/// text matches _lastUrl (meaning the user hasn't typed anything) or is empty.
bool shouldUpdateControllerWhenFocused({
  required String controllerText,
  required String lastUrl,
}) {
  return controllerText == lastUrl || controllerText.isEmpty;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('webview_cef'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'create') {
          return [1, 1]; // browserId, textureId
        }
        return null;
      },
    );
  });

  // ── BrowserState getter tests ──────────────────────────────────────────────

  group('BrowserState getters', () {
    test('active tab provides correct title and url', () {
      final state = _stateWith(
        _tab(url: 'https://flutter.dev', title: 'Flutter – Build apps'),
      );
      expect(state.title, 'Flutter – Build apps');
      expect(state.currentUrl, 'https://flutter.dev');
      expect(state.isHomePage, false);
    });

    test('no tabs → home page state', () {
      const state = BrowserState.initial();
      expect(state.isHomePage, true);
      expect(state.currentUrl, '');
      expect(state.title, '');
    });

    test('home-page tab → isHomePage is true', () {
      final state = _stateWith(
        _tab(url: '', title: '', isHomePage: true),
      );
      expect(state.isHomePage, true);
    });

    test('tab switch → active tab reflects correct values', () {
      final tab1 = _tab(url: 'https://flutter.dev', title: 'Flutter', id: 'tab_1');
      final tab2 = _tab(url: 'https://github.com', title: 'GitHub', id: 'tab_2');

      final onTab1 = _stateWithTabs([tab1, tab2], activeIndex: 0);
      final onTab2 = _stateWithTabs([tab1, tab2], activeIndex: 1);

      expect(onTab1.title, 'Flutter');
      expect(onTab1.currentUrl, 'https://flutter.dev');

      expect(onTab2.title, 'GitHub');
      expect(onTab2.currentUrl, 'https://github.com');
    });
  });

  // ── Display logic unit tests ───────────────────────────────────────────────

  group('Address bar display logic', () {
    test('unfocused → shows page title', () {
      final state = _stateWith(
        _tab(url: 'https://tourism.ladakh.gov.in/gallery', title: 'Gallery | Ladakh Tourism'),
      );
      expect(
        addressBarDisplayText(hasFocus: false, state: state),
        'Gallery | Ladakh Tourism',
      );
    });

    test('focused → shows full URL', () {
      final state = _stateWith(
        _tab(url: 'https://tourism.ladakh.gov.in/gallery', title: 'Gallery | Ladakh Tourism'),
      );
      expect(
        addressBarDisplayText(hasFocus: true, state: state),
        'https://tourism.ladakh.gov.in/gallery',
      );
    });

    test('unfocused + empty title → falls back to URL', () {
      final state = _stateWith(
        _tab(url: 'https://example.com', title: ''),
      );
      expect(
        addressBarDisplayText(hasFocus: false, state: state),
        'https://example.com',
      );
    });

    test('home page unfocused → empty string', () {
      final state = _stateWith(
        _tab(url: '', title: '', isHomePage: true),
      );
      expect(
        addressBarDisplayText(hasFocus: false, state: state),
        '',
      );
    });

    test('home page focused → empty string', () {
      final state = _stateWith(
        _tab(url: '', title: '', isHomePage: true),
      );
      expect(
        addressBarDisplayText(hasFocus: true, state: state),
        '',
      );
    });

    test('unfocused on tab switch → new title shown', () {
      final tab1 = _tab(url: 'https://flutter.dev', title: 'Flutter', id: 'tab_1');
      final tab2 = _tab(url: 'https://github.com', title: 'GitHub', id: 'tab_2');

      final onTab2 = _stateWithTabs([tab1, tab2], activeIndex: 1);
      expect(
        addressBarDisplayText(hasFocus: false, state: onTab2),
        'GitHub',
      );
    });

    test('focused on tab switch → new URL shown', () {
      final tab1 = _tab(url: 'https://flutter.dev', title: 'Flutter', id: 'tab_1');
      final tab2 = _tab(url: 'https://github.com', title: 'GitHub', id: 'tab_2');

      final onTab2 = _stateWithTabs([tab1, tab2], activeIndex: 1);
      expect(
        addressBarDisplayText(hasFocus: true, state: onTab2),
        'https://github.com',
      );
    });
  });

  // ── User-input protection logic tests ─────────────────────────────────────

  group('User input protection (focused)', () {
    test('controller text == lastUrl → should update (redirect scenario)', () {
      expect(
        shouldUpdateControllerWhenFocused(
          controllerText: 'https://example.com',
          lastUrl: 'https://example.com',
        ),
        isTrue,
      );
    });

    test('controller text is empty → should update', () {
      expect(
        shouldUpdateControllerWhenFocused(
          controllerText: '',
          lastUrl: 'https://example.com',
        ),
        isTrue,
      );
    });

    test('user has started typing → should NOT overwrite', () {
      expect(
        shouldUpdateControllerWhenFocused(
          controllerText: 'flutter documentation',
          lastUrl: 'https://example.com',
        ),
        isFalse,
      );
    });

    test('user has partially edited url → should NOT overwrite', () {
      expect(
        shouldUpdateControllerWhenFocused(
          controllerText: 'https://example.com/new-path',
          lastUrl: 'https://example.com',
        ),
        isFalse,
      );
    });
  });

  // ── FocusNode + TextEditingController lifecycle tests (unit) ──────────────

  group('Focus node / controller lifecycle', () {
    test('focus gained → controller switches to URL', () {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final state = _stateWith(
        _tab(url: 'https://flutter.dev', title: 'Flutter – Build apps'),
      );

      // Start unfocused: show title
      controller.text = addressBarDisplayText(hasFocus: false, state: state);
      expect(controller.text, 'Flutter – Build apps');

      // Simulate focus gained
      controller.text = addressBarDisplayText(hasFocus: true, state: state);
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );

      expect(controller.text, 'https://flutter.dev');
      // Verify entire URL is selected
      expect(controller.selection.start, 0);
      expect(controller.selection.end, 'https://flutter.dev'.length);

      controller.dispose();
      focusNode.dispose();
    });

    test('focus lost → controller switches back to title', () {
      final controller = TextEditingController();
      final state = _stateWith(
        _tab(url: 'https://flutter.dev', title: 'Flutter – Build apps'),
      );

      // Start focused: show URL
      controller.text = addressBarDisplayText(hasFocus: true, state: state);
      expect(controller.text, 'https://flutter.dev');

      // Simulate unfocus
      controller.text = addressBarDisplayText(hasFocus: false, state: state);
      expect(controller.text, 'Flutter – Build apps');

      controller.dispose();
    });

    test('unfocused page navigation → controller text updates to new title', () {
      final controller = TextEditingController();
      final statePage1 = _stateWith(
        _tab(url: 'https://page1.com', title: 'Page 1'),
      );
      final statePage2 = _stateWith(
        _tab(url: 'https://page2.com', title: 'Page 2'),
      );

      controller.text = addressBarDisplayText(hasFocus: false, state: statePage1);
      expect(controller.text, 'Page 1');

      // Navigation happens while unfocused
      controller.text = addressBarDisplayText(hasFocus: false, state: statePage2);
      expect(controller.text, 'Page 2');

      controller.dispose();
    });

    test('focused + user typing + state update → controller preserved', () {
      final controller = TextEditingController();
      String lastUrl = 'https://example.com';

      final state = _stateWith(
        _tab(url: 'https://example.com', title: 'Example'),
      );

      // Focus gained → show URL
      controller.text = addressBarDisplayText(hasFocus: true, state: state);
      lastUrl = state.currentUrl;
      expect(controller.text, 'https://example.com');

      // User types something
      controller.text = 'flutter documentation';

      // BLoC emits same state (e.g. suggestions update)
      // The protection check should block the update
      final shouldUpdate = shouldUpdateControllerWhenFocused(
        controllerText: controller.text,
        lastUrl: lastUrl,
      );
      if (shouldUpdate) {
        controller.text = state.currentUrl;
      }

      // User input must be preserved
      expect(controller.text, 'flutter documentation');

      controller.dispose();
    });

    test('submit preserves nav event flow — display title after unfocus', () {
      final controller = TextEditingController();
      String lastUrl = 'https://example.com';

      // 1. Start unfocused on Page 1
      var state = _stateWith(_tab(url: 'https://example.com', title: 'Example'));
      controller.text = addressBarDisplayText(hasFocus: false, state: state);
      expect(controller.text, 'Example');

      // 2. User focuses and sees URL
      controller.text = addressBarDisplayText(hasFocus: true, state: state);
      lastUrl = state.currentUrl;
      expect(controller.text, 'https://example.com');

      // 3. User types new URL and submits
      controller.text = 'https://flutter.dev';
      // (submit event fired → navigation starts → unfocus)

      // 4. New page loads with new title
      state = _stateWith(_tab(url: 'https://flutter.dev', title: 'Flutter'));

      // 5. Unfocused → show new title
      controller.text = addressBarDisplayText(hasFocus: false, state: state);
      lastUrl = state.currentUrl;
      expect(controller.text, 'Flutter');

      controller.dispose();
    });
  });
}
