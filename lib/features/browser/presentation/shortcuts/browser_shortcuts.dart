import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Browser-level keyboard commands.
enum BrowserShortcut {
  newTab,
  newPrivateTab,
  closeTab,
  nextTab,
  previousTab,

  /// Switch to the tab at [BrowserShortcutMatch.tabIndex].
  selectTab,
  selectLastTab,
  focusAddressBar,

  /// Leave the address bar; only acted on while it has focus.
  leaveAddressBar,
  reload,
  back,
  forward,
  home,
  toggleBookmark,
  openHistory,
  openDownloads,
  openBookmarks,
  devTools,
}

class BrowserShortcutMatch {
  final BrowserShortcut shortcut;
  final int? tabIndex;

  const BrowserShortcutMatch(this.shortcut, [this.tabIndex]);

  @override
  bool operator ==(Object other) =>
      other is BrowserShortcutMatch &&
      other.shortcut == shortcut &&
      other.tabIndex == tabIndex;

  @override
  int get hashCode => Object.hash(shortcut, tabIndex);

  @override
  String toString() =>
      'BrowserShortcutMatch($shortcut${tabIndex == null ? '' : ', $tabIndex'})';
}

typedef _Binding = (SingleActivator, BrowserShortcut, int?);

/// Chrome-compatible bindings. Text-editing combinations (Ctrl+A/C/V/X/Z/Y,
/// Ctrl+arrows, Ctrl+Backspace, ...) are deliberately absent so they keep
/// working in the address bar and in page text fields.
final List<_Binding> _bindings = [
  (
    const SingleActivator(
      LogicalKeyboardKey.keyT,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.newTab,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyN,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.newTab,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyN,
      control: true,
      shift: true,
      includeRepeats: false,
    ),
    BrowserShortcut.newPrivateTab,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyW,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.closeTab,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.f4,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.closeTab,
    null,
  ),

  (
    const SingleActivator(LogicalKeyboardKey.tab, control: true),
    BrowserShortcut.nextTab,
    null,
  ),
  (
    const SingleActivator(LogicalKeyboardKey.pageDown, control: true),
    BrowserShortcut.nextTab,
    null,
  ),
  (
    const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true),
    BrowserShortcut.previousTab,
    null,
  ),
  (
    const SingleActivator(LogicalKeyboardKey.pageUp, control: true),
    BrowserShortcut.previousTab,
    null,
  ),
  for (final (i, key) in const [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
  ].indexed)
    (
      SingleActivator(key, control: true, includeRepeats: false),
      BrowserShortcut.selectTab,
      i,
    ),
  (
    const SingleActivator(
      LogicalKeyboardKey.digit9,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.selectLastTab,
    null,
  ),

  (
    const SingleActivator(
      LogicalKeyboardKey.keyL,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.focusAddressBar,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyD,
      alt: true,
      includeRepeats: false,
    ),
    BrowserShortcut.focusAddressBar,
    null,
  ),
  (
    const SingleActivator(LogicalKeyboardKey.f6, includeRepeats: false),
    BrowserShortcut.focusAddressBar,
    null,
  ),
  (
    const SingleActivator(LogicalKeyboardKey.escape, includeRepeats: false),
    BrowserShortcut.leaveAddressBar,
    null,
  ),

  (
    const SingleActivator(
      LogicalKeyboardKey.keyR,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.reload,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyR,
      control: true,
      shift: true,
      includeRepeats: false,
    ),
    BrowserShortcut.reload,
    null,
  ),
  (
    const SingleActivator(LogicalKeyboardKey.f5, includeRepeats: false),
    BrowserShortcut.reload,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.browserRefresh,
      includeRepeats: false,
    ),
    BrowserShortcut.reload,
    null,
  ),

  (
    const SingleActivator(
      LogicalKeyboardKey.arrowLeft,
      alt: true,
      includeRepeats: false,
    ),
    BrowserShortcut.back,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.browserBack,
      includeRepeats: false,
    ),
    BrowserShortcut.back,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.arrowRight,
      alt: true,
      includeRepeats: false,
    ),
    BrowserShortcut.forward,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.browserForward,
      includeRepeats: false,
    ),
    BrowserShortcut.forward,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.home,
      alt: true,
      includeRepeats: false,
    ),
    BrowserShortcut.home,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.browserHome,
      includeRepeats: false,
    ),
    BrowserShortcut.home,
    null,
  ),

  (
    const SingleActivator(
      LogicalKeyboardKey.keyD,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.toggleBookmark,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyH,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.openHistory,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyJ,
      control: true,
      includeRepeats: false,
    ),
    BrowserShortcut.openDownloads,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyO,
      control: true,
      shift: true,
      includeRepeats: false,
    ),
    BrowserShortcut.openBookmarks,
    null,
  ),

  (
    const SingleActivator(LogicalKeyboardKey.f12, includeRepeats: false),
    BrowserShortcut.devTools,
    null,
  ),
  (
    const SingleActivator(
      LogicalKeyboardKey.keyI,
      control: true,
      shift: true,
      includeRepeats: false,
    ),
    BrowserShortcut.devTools,
    null,
  ),
];

/// Returns the browser command for [event], or null if it is not a browser
/// shortcut (and should go to the page / focused text field as usual).
BrowserShortcutMatch? matchBrowserShortcut(
  KeyEvent event, [
  HardwareKeyboard? keyboard,
]) {
  final state = keyboard ?? HardwareKeyboard.instance;
  for (final (activator, shortcut, index) in _bindings) {
    if (activator.accepts(event, state)) {
      return BrowserShortcutMatch(shortcut, index);
    }
  }
  return null;
}
