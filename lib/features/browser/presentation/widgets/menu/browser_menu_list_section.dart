import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

import 'menu_popup_list_tile.dart';

class BrowserMenuListSection extends StatelessWidget {
  final BrowserState state;
  final bool isDesktopSite;
  final ValueChanged<bool> onToggleDesktopSite;
  final VoidCallback hideMenu; // hide pop up menu

  const BrowserMenuListSection({
    super.key,
    required this.state,
    required this.isDesktopSite,
    required this.onToggleDesktopSite,
    required this.hideMenu,
  });

  void _handleNewTab(BuildContext context) {
    hideMenu();
    if (state.isInitialized) {
      context.read<BrowserBloc>().add(const BrowserNewTabRequested());
    }
  }

  void _handleNewPrivateTab(BuildContext context) {
    hideMenu();
    if (state.isInitialized) {
      context.read<BrowserBloc>().add(
        const BrowserNewTabRequested(isPrivate: true),
      );
    }
  }

  Future<void> _handleNavigateToRoute(
    BuildContext context,
    String routeName,
  ) async {
    try {
      final navigator = Navigator.of(context);
      hideMenu();
      context.read<BrowserBloc>().add(const BrowserWasHiddenRequested(true));
      await navigator.pushNamed(routeName);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error navigating to $routeName',
        error: e,
        stack: stackTrace,
      );
    } finally {
      if (context.mounted) {
        context.read<BrowserBloc>().add(const BrowserWasHiddenRequested(false));
      }
    }
  }

  void _handleShare() {
    hideMenu(); // TODO: we implement share functionality here
  }

  void _handleDevTools(BuildContext context) {
    hideMenu();
    if (state.isInitialized) {
      context.read<BrowserBloc>().add(const BrowserDevToolsRequested());
    }
  }

  void _handleToggleDesktopSite() {
    onToggleDesktopSite(!isDesktopSite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            MenuPopupListTile(
              icon: Icons.add,
              label: l10n.newTab,
              onTap: () => _handleNewTab(context),
            ),
            MenuPopupListTile(
              icon: Icons.visibility_off_outlined,
              label: l10n.newPrivateTab,
              onTap: () => _handleNewPrivateTab(context),
            ),
            MenuPopupListTile(
              icon: Icons.history,
              label: l10n.history,
              onTap: () => _handleNavigateToRoute(context, AppRoutes.history),
            ),
            MenuPopupListTile(
              icon: Icons.bookmark_border_rounded,
              label: l10n.bookmarks,
              onTap: () => _handleNavigateToRoute(context, AppRoutes.bookmarks),
            ),
            MenuPopupListTile(
              icon: Icons.download_outlined,
              label: l10n.downloads,
              onTap: () => _handleNavigateToRoute(context, AppRoutes.downloads),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: colors.panelBorder,
                height: 16,
                thickness: 1,
              ),
            ),
            MenuPopupListTile(
              icon: Icons.share_outlined,
              label: l10n.share,
              onTap: _handleShare,
            ),
            MenuPopupListTile(
              icon: Icons.computer_outlined,
              label: l10n.desktopSite,
              trailing: Checkbox(
                value: isDesktopSite,
                activeColor: colors.accentActive,
                checkColor: colors.searchBarText,
                onChanged: (val) {
                  onToggleDesktopSite(val ?? false);
                },
              ),
              onTap: _handleToggleDesktopSite,
            ),
            MenuPopupListTile(
              icon: Icons.developer_mode_outlined,
              label: l10n.developerTools,
              onTap: () => _handleDevTools(context),
            ),
            MenuPopupListTile(
              icon: Icons.settings_outlined,
              label: l10n.settings,
              onTap: () => _handleNavigateToRoute(context, AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}
