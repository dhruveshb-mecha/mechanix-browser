part of 'download_bloc.dart';

enum DownloadErrorType {
  initializationFailed,
  startFailed,
  cancelFailed,
  pauseFailed,
  resumeFailed,
  removeFailed,
  retryFailed,
  restartFailed,
  clearFailed,
}

class DownloadState extends Equatable {
  final List<BrowserDownload> downloads;
  final BrowserDownload? lastStartedOrUpdated;
  final DownloadErrorType? errorType;

  const DownloadState({
    required this.downloads,
    this.lastStartedOrUpdated,
    this.errorType,
  });

  factory DownloadState.initial() => const DownloadState(downloads: []);

  int get activeDownloadsCount => downloads
      .where(
        (d) =>
            d.status == DownloadStatus.downloading ||
            d.status == DownloadStatus.pending,
      )
      .length;

  bool get hasActiveDownloads => activeDownloadsCount > 0;
  bool get hasError => errorType != null;

  DownloadState copyWith({
    List<BrowserDownload>? downloads,
    BrowserDownload? lastStartedOrUpdated,
    DownloadErrorType? errorType,
    bool clearError = false,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      lastStartedOrUpdated: lastStartedOrUpdated ?? this.lastStartedOrUpdated,
      errorType: clearError ? null : (errorType ?? this.errorType),
    );
  }

  @override
  List<Object?> get props => [downloads, lastStartedOrUpdated, errorType];
}
