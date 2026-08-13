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
  String _lastUrl = '';

  @override
  void initState() {
    super.initState();
    // Listen for focus changes on the URL address bar input field
    _focusNode.addListener(_onFocusChange);

    final bloc = context.read<BrowserBloc>();
    final state = bloc.state;
    _lastUrl = state.currentUrl;

    // Display empty text if on home page, otherwise show page title (or fallback to URL)
    if (state.isHomePage) {
      _textController.text = '';
    } else {
      _textController.text = state.title.isNotEmpty
          ? state.title
          : state.currentUrl;
    }
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {});

    final bloc = context.read<BrowserBloc>();
    final state = bloc.state;

    if (_focusNode.hasFocus) {
      // When focused: display full current URL and select all text for easy editing
      if (!state.isHomePage) {
        _textController.text = state.currentUrl;
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      }
      // Show search suggestions overlay
      _showOverlay();
      bloc.add(BrowserSearchQueryChanged(_textController.text));

      // keep bottom bar visible during user interaction
      context.read<BrowserBloc>().add(
        const BrowserBottomBarVisibilityChanged(true, isInteracting: true),
      );
    } else {
      // When unfocused: restore display title (or empty string if on home page)
      if (state.isHomePage) {
        _textController.text = '';
      } else {
        _textController.text = state.title.isNotEmpty
            ? state.title
            : state.currentUrl;
      }
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
          bottom: 60,
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
      context.read<BrowserBloc>().add(
        const BrowserBottomBarVisibilityChanged(true, isInteracting: false),
      );
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _showMenu() {
    if (_menuOverlayEntry != null) return;

    final bloc = context.read<BrowserBloc>();
    bloc.add(
      const BrowserBottomBarVisibilityChanged(true, isInteracting: true),
    );

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
                child: BlocProvider.value(
                  value: bloc,
                  child: BrowserMenuPopupContent(
                    hideMenu: _hideMenu,
                    onFindInPage: () {
                      _hideMenu();
                      _focusNode.requestFocus();
                    },
                  ),
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
      if (mounted) {
        context.read<BrowserBloc>().add(
          const BrowserBottomBarVisibilityChanged(true, isInteracting: false),
        );
      }
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

    return BlocListener<BrowserBloc, BrowserState>(
      listenWhen: (previous, current) =>
          previous.currentUrl != current.currentUrl ||
          previous.title != current.title ||
          previous.isHomePage != current.isHomePage,
      listener: (context, state) {
        final currentUrl = state.currentUrl;
        final title = state.title;

        if (_focusNode.hasFocus) {
          if (state.isHomePage) {
            _textController.text = '';
          } else {
            if (_textController.text == _lastUrl ||
                _textController.text.isEmpty) {
              _textController.text = currentUrl;
            }
          }
        } else {
          if (state.isHomePage) {
            _textController.text = '';
          } else {
            _textController.text = title.isNotEmpty ? title : currentUrl;
          }
        }
        _lastUrl = currentUrl;
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
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: BrowserSearchInput(
                      focusNode: _focusNode,
                      controller: _textController,
                      isPrivate: state.mode == BrowserMode.private,
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
                      // isPrivate: state.mode == BrowserMode.private,
                      onNewTab: () {
                        if (state.isInitialized) {
                          bloc.add(
                            BrowserNewTabRequested(
                              isPrivate: state.mode == BrowserMode.private,
                            ),
                          );
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
