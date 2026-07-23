import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

import 'menu_popup_button.dart';

class BrowserMenuBottomBar extends StatelessWidget {
  final BrowserBloc bloc;
  final BrowserState state;
  final VoidCallback onDismiss;
  final VoidCallback? onFindInPage;

  const BrowserMenuBottomBar({
    super.key,
    required this.bloc,
    required this.state,
    required this.onDismiss,
    this.onFindInPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

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
              onDismiss();
              if (state.isInitialized) {
                bloc.add(BrowserGoBackRequested());
              }
            },
          ),
          MenuPopupButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              onDismiss();
              if (state.isInitialized) {
                bloc.add(BrowserGoForwardRequested());
              }
            },
          ),
          MenuPopupButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              onDismiss();
              if (state.isInitialized) {
                bloc.add(BrowserReloadRequested());
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
                bloc.add(
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
              onDismiss();
              onFindInPage?.call();
            },
          ),
        ],
      ),
    );
  }
}
