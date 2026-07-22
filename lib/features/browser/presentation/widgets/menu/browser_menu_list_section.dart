import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

import 'menu_popup_list_tile.dart';

class BrowserMenuListSection extends StatelessWidget {
  final BrowserBloc bloc;
  final BrowserState state;
  final bool isDesktopSite;
  final ValueChanged<bool> onToggleDesktopSite;
  final VoidCallback onDismiss;

  const BrowserMenuListSection({
    super.key,
    required this.bloc,
    required this.state,
    required this.isDesktopSite,
    required this.onToggleDesktopSite,
    required this.onDismiss,
  });

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
              onTap: () {
                onDismiss();
                if (state.isInitialized) {
                  bloc.add(const BrowserNewTabRequested());
                }
              },
            ),
            MenuPopupListTile(
              icon: Icons.visibility_off_outlined,
              label: l10n.newPrivateTab,
              onTap: () {
                onDismiss();
                if (state.isInitialized) {
                  bloc.add(const BrowserNewTabRequested(isPrivate: true));
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.privateTabOpened),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            MenuPopupListTile(
              icon: Icons.history,
              label: l10n.history,
              onTap: () {
                onDismiss();
                Navigator.pushNamed(context, AppRoutes.history);
              },
            ),
            MenuPopupListTile(
              icon: Icons.bookmark_border_rounded,
              label: l10n.bookmarks,
              onTap: () {
                onDismiss();
                Navigator.pushNamed(context, AppRoutes.bookmarks);
              },
            ),
            MenuPopupListTile(
              icon: Icons.download_outlined,
              label: l10n.downloads,
              onTap: () {
                onDismiss();
                Navigator.pushNamed(context, AppRoutes.downloads);
              },
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
              onTap: () {
                onDismiss();
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.sharingPage),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
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
              onTap: () {
                onToggleDesktopSite(!isDesktopSite);
              },
            ),
            MenuPopupListTile(
              icon: Icons.settings_outlined,
              label: l10n.settings,
              onTap: () {
                onDismiss();
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }
}
