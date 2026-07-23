import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_service.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

import 'download_file_badge.dart';
import 'download_progress_bar.dart';

class DownloadItemCard extends StatelessWidget {
  final BrowserDownload download;

  const DownloadItemCard({super.key, required this.download});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return InkWell(
      onTap: download.status == DownloadStatus.completed
          ? () => DownloadService.openDownloadedFile(download.destinationPath)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.panelBackground.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DownloadFileBadge(download: download),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.filename,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.searchBarText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _DownloadMetaText(download: download),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DownloadActionButtons(download: download),
              ],
            ),
            if (download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.paused ||
                download.status == DownloadStatus.pending ||
                download.status == DownloadStatus.failed ||
                download.status == DownloadStatus.cancelled) ...[
              const SizedBox(height: 12),
              DownloadProgressBar(download: download),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadMetaText extends StatelessWidget {
  final BrowserDownload download;

  const _DownloadMetaText({required this.download});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    if (download.status == DownloadStatus.failed ||
        download.status == DownloadStatus.cancelled) {
      final reason =
          download.errorMessage ??
          (download.status == DownloadStatus.cancelled
              ? l10n.cancelled
              : l10n.networkError);
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(),
          children: [
            TextSpan(text: '${download.domain} · '),
            TextSpan(
              text: l10n.failed,
              style: const TextStyle(
                color: Color(0xFFE54D42),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: ' · $reason'),
          ],
        ),
      );
    }

    return Text(
      download.metaText,
      style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DownloadActionButtons extends StatelessWidget {
  final BrowserDownload download;

  const _DownloadActionButtons({required this.download});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DownloadBloc>();
    final l10n = AppLocalizations.of(context)!;

    if (download.status == DownloadStatus.downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DownloadActionButton(
            icon: Icons.pause_rounded,
            onPressed: () =>
                bloc.add(DownloadPauseRequested(download.downloadId)),
          ),
          _DownloadActionButton(
            icon: Icons.close_rounded,
            onPressed: () =>
                bloc.add(DownloadCancelRequested(download.downloadId)),
          ),
        ],
      );
    }

    if (download.status == DownloadStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DownloadActionButton(
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                bloc.add(DownloadResumeRequested(download.downloadId)),
          ),
          _DownloadActionButton(
            icon: Icons.close_rounded,
            onPressed: () =>
                bloc.add(DownloadCancelRequested(download.downloadId)),
          ),
        ],
      );
    }

    if (download.status == DownloadStatus.failed ||
        download.status == DownloadStatus.cancelled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DownloadActionButton(
            icon: Icons.refresh_rounded,
            onPressed: () => bloc.add(DownloadRetryRequested(download)),
          ),
          _DownloadActionButton(
            icon: Icons.close_rounded,
            onPressed: () =>
                bloc.add(DownloadRemoveRequested(download.downloadId)),
          ),
        ],
      );
    }

    // Completed
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DownloadActionButton(
          icon: Icons.folder_open_rounded,
          tooltip: l10n.openFolder,
          onPressed: () =>
              DownloadService.openDownloadFolder(download.destinationPath),
        ),
        _DownloadActionButton(
          icon: Icons.close_rounded,
          onPressed: () =>
              bloc.add(DownloadRemoveRequested(download.downloadId)),
        ),
      ],
    );
  }
}

class _DownloadActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _DownloadActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return IconButton(
      icon: Icon(icon, size: 20),
      color: colors.textSecondary,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
