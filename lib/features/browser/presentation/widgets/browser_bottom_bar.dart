import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/bottom_bar/browser_bottom_actions.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/bottom_bar/browser_search_input.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_menu_popup.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_suggestions_panel.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/tab_switcher_sheet.dart';

class BrowserBottomBar extends StatefulWidget {
  const BrowserBottomBar({super.key});

  @override
  State<BrowserBottomBar> createState() => _BrowserBottomBarState();
}

class _BrowserBottomBarState extends State<BrowserBottomBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _menuOverlayEntry;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {});
    if (_focusNode.hasFocus) {
      _showOverlay();
      context.read<BrowserBloc>().add(
        BrowserSearchQueryChanged(_textController.text),
      );
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final bloc = context.read<BrowserBloc>();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 72,
          child: Material(
            color: Colors.transparent,
            child: TapRegion(
              groupId: 'browser_search',
              child: BlocProvider.value(
                value: bloc,
                child: BlocBuilder<BrowserBloc, BrowserState>(
                  builder: (context, state) {
                    if (state.searchResults.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return BrowserSuggestionsPanel(
                      textController: _textController,
                      focusNode: _focusNode,
                      bloc: bloc,
                      state: state,
                      onTapItem: () {
                        _hideOverlay();
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _showMenu() {
    if (_menuOverlayEntry != null) return;

    final bloc = context.read<BrowserBloc>();

    _menuOverlayEntry = OverlayEntry(
      builder: (context) {
        final colors = Theme.of(context).extension<AppColorsExtension>()!;
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideMenu,
              child: Container(color: colors.popupBarrierColor),
            ),
            Positioned(
              right: 16,
              bottom: 76,
              width: 320,
              child: Material(
                color: Colors.transparent,
                child: BrowserMenuPopupContent(
                  bloc: bloc,
                  onDismiss: _hideMenu,
                  onFindInPage: () {
                    _hideMenu();
                    _focusNode.requestFocus();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_menuOverlayEntry!);
  }

  void _hideMenu() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideOverlay();
    _hideMenu();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BrowserBloc>();
    final theme = Theme.of(context);

    return BlocListener<BrowserBloc, BrowserState>(
      listenWhen: (previous, current) =>
          previous.currentUrl != current.currentUrl ||
          previous.title != current.title ||
          previous.isHomePage != current.isHomePage,
      listener: (context, state) {
        if (state.isHomePage) {
          _textController.text = '';
        } else {
          _textController.text = state.title.isNotEmpty
              ? state.title
              : state.currentUrl;
        }
      },
      child: BlocBuilder<BrowserBloc, BrowserState>(
        buildWhen: (previous, current) =>
            previous.isInitialized != current.isInitialized ||
            previous.tabs.length != current.tabs.length,
        builder: (context, state) {
          return TapRegion(
            groupId: 'browser_search',
            onTapOutside: (event) {
              _hideOverlay();
              _focusNode.unfocus();
              context.read<BrowserBloc>().add(
                const BrowserSearchQueryChanged(''),
              );
            },
            child: Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: BrowserSearchInput(
                      focusNode: _focusNode,
                      controller: _textController,
                      onChanged: (value) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(
                          const Duration(milliseconds: 200),
                          () {
                            bloc.add(BrowserSearchQueryChanged(value));
                          },
                        );
                      },
                      onSubmitted: (url) {
                        if (state.isInitialized) {
                          bloc.add(BrowserUrlLoadRequested(url));
                          bloc.add(const BrowserSearchQueryChanged(''));
                          _hideOverlay();
                          _focusNode.unfocus();
                        }
                      },
                    ),
                  ),
                  if (!_focusNode.hasFocus)
                    BrowserBottomActions(
                      tabCount: state.tabs.length,
                      onNewTab: () {
                        if (state.isInitialized) {
                          bloc.add(const BrowserNewTabRequested());
                          bloc.add(const BrowserSearchQueryChanged(''));
                          _hideOverlay();
                          _focusNode.unfocus();
                        }
                      },
                      onOpenTabs: () {
                        if (state.isInitialized) {
                          _hideOverlay();
                          _focusNode.unfocus();
                          TabSwitcherSheet.show(context, bloc);
                        }
                      },
                      onOpenMenu: () {
                        _hideOverlay();
                        _focusNode.unfocus();
                        _showMenu();
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
