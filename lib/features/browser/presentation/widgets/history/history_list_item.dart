import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class HistoryListItem extends StatelessWidget {
  final BrowserHistory item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  String _getInitialLetter(String title, String url) {
    final cleanTitle = title.trim();
    if (cleanTitle.isNotEmpty) {
      return cleanTitle[0].toUpperCase();
    }
    final cleanUrl = url
        .replaceFirst(RegExp(r'https?://'), '')
        .replaceFirst('www.', '');
    if (cleanUrl.isNotEmpty) {
      return cleanUrl[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final initial = _getInitialLetter(item.title, item.url);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.panelBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.dividerColor, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isNotEmpty ? item.title : item.url,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.url,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, color: colors.textSecondary, size: 18),
              onPressed: onDelete,
              hoverColor: colors.closeButtonBackground,
              splashRadius: 18,
              tooltip: l10n.delete,
            ),
          ],
        ),
      ),
    );
  }
}
