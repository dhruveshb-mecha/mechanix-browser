part of 'download_bloc.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class DownloadBeforeStarted extends DownloadEvent {
  final WebViewController controller;
  final int downloadId;
  final String url;
  final String suggestedName;
  final String contentDisposition;
  final String mimeType;
  final int totalBytes;
  final bool isPrivate;

  const DownloadBeforeStarted({
    required this.controller,
    required this.downloadId,
    required this.url,
    required this.suggestedName,
    required this.contentDisposition,
    required this.mimeType,
    required this.totalBytes,
    this.isPrivate = false,
  });

  @override
  List<Object?> get props => [
    controller,
    downloadId,
    url,
    suggestedName,
    contentDisposition,
    mimeType,
    totalBytes,
    isPrivate,
  ];
}

class DownloadUpdatedEvent extends DownloadEvent {
  final WebViewController controller;
  final int downloadId;
  final String url;
  final String fullPath;
  final int receivedBytes;
  final int totalBytes;
  final int currentSpeed;
  final int percentComplete;
  final bool isInProgress;
  final bool isComplete;
  final bool isCanceled;
  final bool isInterrupted;
  final int interruptReason;

  const DownloadUpdatedEvent({
    required this.controller,
    required this.downloadId,
    required this.url,
    required this.fullPath,
    required this.receivedBytes,
    required this.totalBytes,
    required this.currentSpeed,
    required this.percentComplete,
    required this.isInProgress,
    required this.isComplete,
    required this.isCanceled,
    required this.isInterrupted,
    required this.interruptReason,
  });

  @override
  List<Object?> get props => [
    controller,
    downloadId,
    url,
    fullPath,
    receivedBytes,
    totalBytes,
    currentSpeed,
    percentComplete,
    isInProgress,
    isComplete,
    isCanceled,
    isInterrupted,
    interruptReason,
  ];
}

class DownloadInitializeRequested extends DownloadEvent {
  const DownloadInitializeRequested();
}

class DownloadCancelRequested extends DownloadEvent {
  final int downloadId;

  const DownloadCancelRequested(this.downloadId);

  @override
  List<Object?> get props => [downloadId];
}

class DownloadPauseRequested extends DownloadEvent {
  final int downloadId;

  const DownloadPauseRequested(this.downloadId);

  @override
  List<Object?> get props => [downloadId];
}

class DownloadResumeRequested extends DownloadEvent {
  final int downloadId;
  final WebViewController? controller;

  const DownloadResumeRequested(this.downloadId, {this.controller});

  @override
  List<Object?> get props => [downloadId, controller];
}

class DownloadRemoveRequested extends DownloadEvent {
  final int downloadId;
  final bool deleteFile;

  const DownloadRemoveRequested(this.downloadId, {this.deleteFile = false});

  @override
  List<Object?> get props => [downloadId, deleteFile];
}

class DownloadRetryRequested extends DownloadEvent {
  final BrowserDownload download;
  final WebViewController? controller;

  const DownloadRetryRequested(this.download, {this.controller});

  @override
  List<Object?> get props => [download, controller];
}

class DownloadRestartRequested extends DownloadEvent {
  final BrowserDownload download;
  final WebViewController? controller;

  const DownloadRestartRequested(this.download, {this.controller});

  @override
  List<Object?> get props => [download, controller];
}

class DownloadClearCompletedRequested extends DownloadEvent {
  final bool deleteFiles;

  const DownloadClearCompletedRequested({this.deleteFiles = false});

  @override
  List<Object?> get props => [deleteFiles];
}
