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

              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.clearFinished,
                onPressed: () => context.read<DownloadBloc>().add(
                  const DownloadClearCompletedRequested(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: l10n.openDownloadsFolder,
            onPressed: () async {
              final path = await DownloadService.getDownloadsDirectoryPath();
              await DownloadService.openDownloadFolder(path);
            },
          ),
        ],
      ),
      body: BlocBuilder<DownloadBloc, DownloadState>(
        builder: (context, state) {
          if (state.downloads.isEmpty) {
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
                key: ValueKey('download_${download.downloadId}'),
                download: download,
              );
            },
          );
        },
      ),
    );
  }
}
