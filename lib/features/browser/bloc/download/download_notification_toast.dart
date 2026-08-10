import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

/// Overlay widget showing a temporary download notification toast at the bottom right of the browser.
/// Automatically hides after 4 seconds of inactivity or upon user interaction.
class DownloadNotificationOverlay extends StatefulWidget {
  const DownloadNotificationOverlay({super.key});

  @override
  State<DownloadNotificationOverlay> createState() =>
      _DownloadNotificationOverlayState();
}

class _DownloadNotificationOverlayState
    extends State<DownloadNotificationOverlay> {
  Timer? _autoHideTimer;
  bool _isVisible = false;
  BrowserDownload? _activeToastDownload;
  bool _initialized = false;

  void _resetTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _checkDownloadState(DownloadState state) {
    final latest = state.lastStartedOrUpdated;

    if (!_initialized) {
      _initialized = true;
      _activeToastDownload = latest;
      return;
    }

    if (state.activeDownloadsCount == 0) {
      _activeToastDownload = null;
      if (_isVisible) {
        _isVisible = false;
        _autoHideTimer?.cancel();
      }
      return;
    }

    if (latest == null) return;

    final active = _activeToastDownload;

    final isNewerDownload =
        active == null ||
        latest.startTimestamp.isAfter(active.startTimestamp) ||
        (latest.startTimestamp.isAtSameMomentAs(active.startTimestamp) &&
            latest.downloadId != active.downloadId);

    final isSameDownload =
        active != null &&
        (latest.downloadId == active.downloadId ||
            (latest.id != 0 && active.id != 0 && latest.id == active.id));

    if (isNewerDownload && latest.status == DownloadStatus.downloading) {
      _activeToastDownload = latest;
      _isVisible = true;
      _resetTimer();
    } else if (isSameDownload) {
      _activeToastDownload = latest;
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        _checkDownloadState(state);

        final activeDownload = _activeToastDownload;

        if (!_isVisible ||
            state.activeDownloadsCount == 0 ||
            activeDownload == null) {
          return const SizedBox.shrink();
        }

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
                          l10n.downloadingFile(activeDownload.filename),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.searchBarText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeDownload.formattedSpeed,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
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
    _autoHideTimer?.cancel();
    setState(() {
      _isVisible = false;
    });
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
