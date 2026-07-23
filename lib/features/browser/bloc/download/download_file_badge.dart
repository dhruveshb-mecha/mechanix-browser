import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';

class DownloadFileBadge extends StatelessWidget {
  final BrowserDownload download;
  final double size;

  const DownloadFileBadge({
    super.key,
    required this.download,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final extLabel = download.extensionLabel;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.popupBottomButtonBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          extLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.searchBarText.withValues(alpha: 0.9),
            fontSize: extLabel.length > 4 ? 10 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }
}
