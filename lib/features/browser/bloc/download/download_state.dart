part of 'download_bloc.dart';

class DownloadState extends Equatable {
  final List<BrowserDownload> downloads;
  final BrowserDownload? lastStartedOrUpdated;

  const DownloadState({required this.downloads, this.lastStartedOrUpdated});

  factory DownloadState.initial() => const DownloadState(downloads: []);

  int get activeDownloadsCount => downloads
      .where(
        (d) =>
            d.status == DownloadStatus.downloading ||
            d.status == DownloadStatus.pending,
      )
      .length;

  bool get hasActiveDownloads => activeDownloadsCount > 0;

  DownloadState copyWith({
    List<BrowserDownload>? downloads,
    BrowserDownload? lastStartedOrUpdated,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      lastStartedOrUpdated: lastStartedOrUpdated ?? this.lastStartedOrUpdated,
    );
  }

  @override
  List<Object?> get props => [downloads, lastStartedOrUpdated];
}
