import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';
import 'package:webview_cef/webview_cef.dart';

class TabCardItem extends StatelessWidget {
  final BrowserTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const TabCardItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    String displayUrl = l10n.newTab;
    if (tab.currentUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(tab.currentUrl);
        displayUrl = uri.host.isNotEmpty ? uri.host : tab.currentUrl;
      } catch (_) {
        displayUrl = tab.currentUrl;
      }
    }
    final title = tab.title.isNotEmpty ? tab.title : displayUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.popupBottomButtonBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? colors.accentActive : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // WebView preview
            Positioned.fill(
              bottom: 40, // Leave space for the title bar at the bottom
              child: IgnorePointer(child: StaticWebView(tab.controller)),
            ),
            // Fallback for empty/loading tabs
            if (tab.currentUrl.isEmpty)
              Center(
                child: Icon(Icons.public, size: 48, color: colors.dragHandle),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: colors.popupBarrierColor.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.searchBarText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.closeButtonBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: colors.searchBarText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
