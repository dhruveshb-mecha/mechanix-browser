import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class DownloadNotificationOverlay extends StatelessWidget {
  const DownloadNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        final activeCount = state.activeDownloadsCount;
        if (activeCount == 0) return const SizedBox.shrink();

        final latest = state.lastStartedOrUpdated;

        return Positioned(
          bottom: 24,
          right: 24,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: colors.panelBackground,
            child: InkWell(
              onTap: () => _openDownloads(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.dividerColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF5B96F7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          latest != null
                              ? l10n.downloadingFile(latest.filename)
                              : l10n.downloadingFiles,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.searchBarText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (latest != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            latest.formattedSpeed,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDownloads(BuildContext context) async {
    final bloc = context.read<BrowserBloc>();
    final navigator = Navigator.of(context);
    bloc.add(const BrowserWasHiddenRequested(true));
    try {
      await navigator.pushNamed(AppRoutes.downloads);
    } catch (e) {
      AppLogger.i('Error navigating to downloads: $e');
    } finally {
      bloc.add(const BrowserWasHiddenRequested(false));
    }
  }
}
