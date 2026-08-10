import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_item_card.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_service.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  void _showClearFinishedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearDownloadsTitle),
        content: Text(l10n.clearDownloadsDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DownloadBloc>().add(
                const DownloadClearCompletedRequested(deleteFiles: false),
              );
            },
            child: Text(l10n.clearHistoryOnly),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE54D42),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DownloadBloc>().add(
                const DownloadClearCompletedRequested(deleteFiles: true),
              );
            },
            child: Text(l10n.deleteFilesAndHistory),
          ),
        ],
      ),
    );
  }

  String _getLocalizedErrorMessage(
    DownloadErrorType? errorType,
    AppLocalizations l10n,
  ) {
    switch (errorType) {
      case DownloadErrorType.initializationFailed:
        return l10n.downloadInitError;
      case DownloadErrorType.startFailed:
        return l10n.downloadStartError;
      case DownloadErrorType.cancelFailed:
        return l10n.downloadCancelError;
      case DownloadErrorType.pauseFailed:
        return l10n.downloadPauseError;
      case DownloadErrorType.resumeFailed:
        return l10n.downloadResumeError;
      case DownloadErrorType.removeFailed:
        return l10n.downloadRemoveError;
      case DownloadErrorType.retryFailed:
        return l10n.downloadRetryError;
      case DownloadErrorType.restartFailed:
        return l10n.downloadRestartError;
      case DownloadErrorType.clearFailed:
        return l10n.downloadClearError;
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.downloads,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          BlocBuilder<DownloadBloc, DownloadState>(
            builder: (context, state) {
              final hasCompleted = state.downloads.any(
                (d) =>
                    d.status == DownloadStatus.completed ||
                    d.status == DownloadStatus.cancelled ||
                    d.status == DownloadStatus.failed,
              );

              if (!hasCompleted) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: l10n.clearFinished,
                  onPressed: () => _showClearFinishedDialog(context),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: l10n.openDownloadsFolder,
              onPressed: () async {
                final path = await DownloadService.getDownloadsDirectoryPath();
                await DownloadService.openDownloadFolder(path);
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<DownloadBloc, DownloadState>(
        listenWhen: (previous, current) =>
            current.hasError && previous.errorType != current.errorType,
        listener: (context, state) {
          final message = _getLocalizedErrorMessage(state.errorType, l10n);
          if (message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.downloads.isEmpty) {
            if (state.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.panelBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getLocalizedErrorMessage(state.errorType, l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.searchBarText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.panelBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.download_outlined,
                      color: colors.textSecondary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.noDownloadsYet,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.searchBarText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noDownloadsDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: state.downloads.length,
            itemBuilder: (context, index) {
              final download = state.downloads[index];
              return DownloadItemCard(
                key: ValueKey('download_${download.downloadId}_${download.id}'),
                download: download,
              );
            },
          );
        },
      ),
    );
  }
}
