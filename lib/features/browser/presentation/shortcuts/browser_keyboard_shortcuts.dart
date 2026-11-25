import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/shortcuts/browser_shortcuts.dart';

/// Handles browser keyboard shortcuts while the browser screen is the
/// current route.
///
/// Registered as an *early* key handler so a matching key is consumed before
/// the focused webview forwards it to the page (the webview claims every key
/// it receives). Keys that are not browser shortcuts flow on unchanged.
class BrowserKeyboardShortcuts extends StatefulWidget {
  final FocusNode addressBarFocusNode;
  final Widget child;

  const BrowserKeyboardShortcuts({
    super.key,
    required this.addressBarFocusNode,
    required this.child,
  });

  @override
  State<BrowserKeyboardShortcuts> createState() =>
      _BrowserKeyboardShortcutsState();
}

class _BrowserKeyboardShortcutsState extends State<BrowserKeyboardShortcuts> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_onKeyEvent);
    super.dispose();
  }

  KeyEventResult _onKeyEvent(KeyEvent event) {
    if (!mounted) return KeyEventResult.ignored;
    // Dialogs, sheets, the tab switcher and pushed screens sit on top of this
    // route; leave their keys alone.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      return KeyEventResult.ignored;
    }
    final match = matchBrowserShortcut(event);
    if (match == null) return KeyEventResult.ignored;
    return _perform(match) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  /// Returns false when the shortcut does not apply right now, so the key
  /// reaches the page instead.
  bool _perform(BrowserShortcutMatch match) {
    final bloc = context.read<BrowserBloc>();
    final state = bloc.state;
    if (!state.isInitialized) return false;

    final tabs = state.tabs;
    final activeTab = state.activeTab;

    void switchTo(int index) {
      if (index < 0 || index >= tabs.length) return;
      if (tabs[index].id == activeTab?.id) return;
      bloc.add(BrowserSwitchTabRequested(tabs[index].id));
    }

    switch (match.shortcut) {
      case BrowserShortcut.newTab:
        // Like Chrome: Ctrl+T in private mode opens another private tab.
        bloc.add(
          BrowserNewTabRequested(isPrivate: state.mode == BrowserMode.private),
        );
      case BrowserShortcut.newPrivateTab:
        bloc.add(const BrowserNewTabRequested(isPrivate: true));
      case BrowserShortcut.closeTab:
        if (activeTab == null) return true;
        bloc.add(BrowserCloseTabRequested(activeTab.id));
      case BrowserShortcut.nextTab:
        if (tabs.length > 1) switchTo((state.activeTabIndex + 1) % tabs.length);
      case BrowserShortcut.previousTab:
        if (tabs.length > 1) {
          switchTo((state.activeTabIndex - 1 + tabs.length) % tabs.length);
        }
      case BrowserShortcut.selectTab:
        switchTo(match.tabIndex!);
      case BrowserShortcut.selectLastTab:
        switchTo(tabs.length - 1);
      case BrowserShortcut.focusAddressBar:
        bloc.add(
          const BrowserBottomBarVisibilityChanged(true, isInteracting: true),
        );
        widget.addressBarFocusNode.requestFocus();
      case BrowserShortcut.leaveAddressBar:
        // Escape belongs to the page unless the address bar has focus.
        if (!widget.addressBarFocusNode.hasFocus) return false;
        // The bottom bar closes its suggestions when focus leaves.
        widget.addressBarFocusNode.unfocus();
      case BrowserShortcut.reload:
        if (state.isHomePage) return true;
        bloc.add(const BrowserReloadRequested());
      case BrowserShortcut.back:
        bloc.add(const BrowserGoBackRequested());
      case BrowserShortcut.forward:
        bloc.add(const BrowserGoForwardRequested());
      case BrowserShortcut.home:
        bloc.add(const BrowserGoHomeRequested());
      case BrowserShortcut.toggleBookmark:
        if (state.isHomePage || state.currentUrl.isEmpty) return true;
        bloc.add(
          BrowserBookmarkToggled(url: state.currentUrl, title: state.title),
        );
      case BrowserShortcut.openHistory:
        _openRoute(AppRoutes.history);
      case BrowserShortcut.openDownloads:
        _openRoute(AppRoutes.downloads);
      case BrowserShortcut.openBookmarks:
        _openRoute(AppRoutes.bookmarks);
      case BrowserShortcut.devTools:
        bloc.add(const BrowserDevToolsRequested());
    }
    return true;
  }

  /// Same flow as the menu: hide the webview while another screen is shown.
  Future<void> _openRoute(String routeName) async {
    final bloc = context.read<BrowserBloc>();
    final navigator = Navigator.of(context);
    widget.addressBarFocusNode.unfocus();
    bloc.add(const BrowserWasHiddenRequested(true));
    try {
      await navigator.pushNamed(routeName);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error navigating to $routeName',
        error: e,
        stack: stackTrace,
      );
    } finally {
      bloc.add(const BrowserWasHiddenRequested(false));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
