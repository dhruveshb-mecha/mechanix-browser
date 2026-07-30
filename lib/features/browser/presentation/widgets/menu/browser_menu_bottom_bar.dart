import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';

import 'menu_popup_button.dart';

class BrowserMenuBottomBar extends StatelessWidget {
  final BrowserState state;
  final VoidCallback hideMenu; // hide pop up menu
  final VoidCallback? onFindInPage;

  const BrowserMenuBottomBar({
    super.key,
    required this.state,
    required this.hideMenu,
    this.onFindInPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.popupBottomBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MenuPopupButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              hideMenu();
              if (state.isInitialized) {
                context.read<BrowserBloc>().add(BrowserGoBackRequested());
              }
            },
          ),
          MenuPopupButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              hideMenu();
              if (state.isInitialized) {
                context.read<BrowserBloc>().add(BrowserGoForwardRequested());
              }
            },
          ),
          MenuPopupButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              hideMenu();
              if (state.isInitialized) {
                context.read<BrowserBloc>().add(BrowserReloadRequested());
              }
            },
          ),
          MenuPopupButton(
            icon: state.isCurrentUrlBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            iconColor: state.isCurrentUrlBookmarked
                ? colors.accentActive
                : colors.searchBarText,
            onTap: () {
              if (state.currentUrl.isNotEmpty) {
                context.read<BrowserBloc>().add(
                  BrowserBookmarkToggled(
                    url: state.currentUrl,
                    title: state.title,
                  ),
                );
              }
            },
          ),
          MenuPopupButton(
            icon: Icons.search_rounded,
            onTap: () {
              hideMenu();
              onFindInPage?.call();
            },
          ),
        ],
      ),
    );
  }
}
