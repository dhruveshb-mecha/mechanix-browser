import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_service.dart';
import 'package:webview_cef/webview_cef.dart';

part 'download_event.dart';
part 'download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final Map<int, WebViewController> _controllerMap = {};

  DownloadBloc() : super(DownloadState.initial()) {
    on<DownloadBeforeStarted>(_onBeforeStarted);
    on<DownloadUpdatedEvent>(_onUpdated);
    on<DownloadCancelRequested>(_onCancelRequested);
    on<DownloadPauseRequested>(_onPauseRequested);
    on<DownloadResumeRequested>(_onResumeRequested);
    on<DownloadRemoveRequested>(_onRemoveRequested);
    on<DownloadRetryRequested>(_onRetryRequested);
    on<DownloadClearCompletedRequested>(_onClearCompleted);
  }

  /// Handler for the initial download trigger event from CEF.
  /// This runs when the browser registers a download request (via webview's OnBeforeDownload).
  Future<void> _onBeforeStarted(
    DownloadBeforeStarted event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      // 1. Store the WebViewController reference to send future download commands (pause, resume, cancel) to CEF.
      _controllerMap[event.downloadId] = event.controller;

      // 2. Resolve the downloads folder and sanitize the filename proposed by CEF.
      final dirPath = await DownloadService.getDownloadsDirectoryPath();
      final sanitizedName = DownloadService.sanitizeFilename(
        event.suggestedName,
        event.url,
      );

      // 3. Generate a unique destination path to avoid overwriting existing files in the download directory.
      final destPath = DownloadService.getUniqueDestinationPath(
        dirPath,
        sanitizedName,
      );

      final extractedFilename = destPath.split('/').last.split('\\').last;

      // 4. Create a new BrowserDownload record with status as downloading.
      final newDownload = BrowserDownload(
        downloadId: event.downloadId,
        browserId: 0,
        url: event.url,
        filename: extractedFilename,
        destinationPath: destPath,
        receivedBytes: 0,
        totalBytes: event.totalBytes,
        currentSpeed: 0,
        progress: 0.0,
        status: DownloadStatus.downloading,
        startTimestamp: DateTime.now(),
      );

      // 5. Update the UI state by inserting the new download at the top of the list.
      final updatedList = List<BrowserDownload>.from(state.downloads)
        ..removeWhere((d) => d.downloadId == event.downloadId)
        ..insert(0, newDownload);

      emit(
        state.copyWith(
          downloads: updatedList,
          lastStartedOrUpdated: newDownload,
        ),
      );

      // 6. Direct CEF to proceed with the download to the resolved destination path without displaying a prompt/dialog.
      await event.controller.continueDownload(
        event.downloadId,
        destPath,
        showDialog: false,
      );
    } catch (e) {
      AppLogger.i('Error handling download before start: $e');
    }
  }

  /// Handler for CEF download progress tick updates.
  /// CEF calls OnDownloadUpdated periodically during transfer, or when the download changes state.
  void _onUpdated(DownloadUpdatedEvent event, Emitter<DownloadState> emit) {
    final index = state.downloads.indexWhere(
      (d) => d.downloadId == event.downloadId,
    );

    // 1. Map the CEF download item flags into the app-defined DownloadStatus.
    DownloadStatus status;
    String? errorMsg;

    switch (event) {
      case _ when event.isComplete:
        status = DownloadStatus.completed;

      case _ when event.isCanceled:
        status = DownloadStatus.cancelled;
        errorMsg = 'Cancelled';

      case _ when event.isInterrupted:
        status = DownloadStatus.failed;
        errorMsg = _getInterruptReasonText(event.interruptReason);

      default:
        status = DownloadStatus.downloading;
    }

    // 2. Compute progress percentage (0.0 to 1.0) based on received and total bytes.
    double progress = 0.0;
    if (event.totalBytes > 0) {
      progress = (event.receivedBytes / event.totalBytes).clamp(0.0, 1.0);
    }

    // 3. Update the existing download model or create one if it wasn't tracked before.
    BrowserDownload updatedDownload;
    if (index != -1) {
      final existing = state.downloads[index];
      final filename = event.fullPath.isNotEmpty
          ? event.fullPath.split('/').last.split('\\').last
          : existing.filename;

      updatedDownload = existing.copyWith(
        filename: filename,
        destinationPath: event.fullPath.isNotEmpty
            ? event.fullPath
            : existing.destinationPath,
        receivedBytes: event.receivedBytes,
        totalBytes: event.totalBytes > 0
            ? event.totalBytes
            : existing.totalBytes,
        currentSpeed: event.currentSpeed,
        progress: progress,
        status: status,
        endTime:
            (status == DownloadStatus.completed ||
                status == DownloadStatus.failed ||
                status == DownloadStatus.cancelled)
            ? DateTime.now()
            : existing.endTime,
        errorMessage: errorMsg,
      );
    } else {
      final filename = event.fullPath.isNotEmpty
          ? event.fullPath.split('/').last.split('\\').last
          : DownloadService.sanitizeFilename('', event.url);

      updatedDownload = BrowserDownload(
        downloadId: event.downloadId,
        browserId: 0,
        url: event.url,
        filename: filename,
        destinationPath: event.fullPath,
        receivedBytes: event.receivedBytes,
        totalBytes: event.totalBytes,
        currentSpeed: event.currentSpeed,
        progress: progress,
        status: status,
        startTimestamp: DateTime.now(),
        endTime:
            (status == DownloadStatus.completed ||
                status == DownloadStatus.failed ||
                status == DownloadStatus.cancelled)
            ? DateTime.now()
            : null,
        errorMessage: errorMsg,
      );
    }

    // 4. Update the downloads list in state with the refreshed progress data.
    final updatedList = List<BrowserDownload>.from(state.downloads);
    if (index != -1) {
      updatedList[index] = updatedDownload;
    } else {
      updatedList.insert(0, updatedDownload);
    }

    emit(
      state.copyWith(
        downloads: updatedList,
        lastStartedOrUpdated: updatedDownload,
      ),
    );

    if (status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled) {
      _controllerMap.remove(event.downloadId);
    }
  }

  /// Cancels an active download.
  /// Sends the cancellation instruction to CEF via the stored WebViewController,
  /// then updates the state to mark the download status as cancelled.
  Future<void> _onCancelRequested(
    DownloadCancelRequested event,
    Emitter<DownloadState> emit,
  ) async {
    final controller = _controllerMap[event.downloadId];
    if (controller != null) {
      await controller.cancelDownload(event.downloadId);
    }
    _controllerMap.remove(event.downloadId);

    final index = state.downloads.indexWhere(
      (d) => d.downloadId == event.downloadId,
    );
    if (index != -1) {
      final updated = state.downloads[index].copyWith(
        status: DownloadStatus.cancelled,
        errorMessage: 'Cancelled',
        endTime: DateTime.now(),
      );
      final updatedList = List<BrowserDownload>.from(state.downloads)
        ..[index] = updated;
      emit(state.copyWith(downloads: updatedList));
    }
  }

  /// Pauses an active download.
  /// Instructs CEF to temporarily halt transfer, and updates the local state to paused.
  Future<void> _onPauseRequested(
    DownloadPauseRequested event,
    Emitter<DownloadState> emit,
  ) async {
    final controller = _controllerMap[event.downloadId];
    if (controller != null) {
      await controller.pauseDownload(event.downloadId);
    }

    final index = state.downloads.indexWhere(
      (d) => d.downloadId == event.downloadId,
    );
    if (index != -1) {
      final updated = state.downloads[index].copyWith(
        status: DownloadStatus.paused,
      );
      final updatedList = List<BrowserDownload>.from(state.downloads)
        ..[index] = updated;
      emit(state.copyWith(downloads: updatedList));
    }
  }

  /// Resumes a paused download.
  /// Sends the resume command to CEF via the cached WebViewController,
  /// then sets the status to downloading.
  Future<void> _onResumeRequested(
    DownloadResumeRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final controller = _controllerMap[event.downloadId];
      if (controller != null) {
        await controller.resumeDownload(event.downloadId);
      }

      final index = state.downloads.indexWhere(
        (d) => d.downloadId == event.downloadId,
      );
      if (index != -1) {
        final updated = state.downloads[index].copyWith(
          status: DownloadStatus.downloading,
        );
        final updatedList = List<BrowserDownload>.from(state.downloads)
          ..[index] = updated;
        emit(state.copyWith(downloads: updatedList));
      }
    } catch (e) {
      AppLogger.i("Error resuming download: $e");
    }
  }

  /// Removes a download item from the local state list.
  /// Also discards the cached WebViewController reference.
  void _onRemoveRequested(
    DownloadRemoveRequested event,
    Emitter<DownloadState> emit,
  ) {
    final updatedList = List<BrowserDownload>.from(state.downloads)
      ..removeWhere((d) => d.downloadId == event.downloadId);
    _controllerMap.remove(event.downloadId);
    emit(state.copyWith(downloads: updatedList));
  }

  /// Retries a failed or cancelled download.
  /// Directs CEF to load/request the URL again, starting a new CEF download process (yielding a new download ID).
  Future<void> _onRetryRequested(
    DownloadRetryRequested event,
    Emitter<DownloadState> emit,
  ) async {
    final controller = _controllerMap[event.download.downloadId];
    if (controller != null && controller.value) {
      await controller.loadUrl(event.download.url);
    }
  }

  /// Clears completed downloads from the history/list.
  /// Keeps only the active downloads (downloading, pending, paused).
  void _onClearCompleted(
    DownloadClearCompletedRequested event,
    Emitter<DownloadState> emit,
  ) {
    final updatedList = state.downloads
        .where(
          (d) =>
              d.status == DownloadStatus.downloading ||
              d.status == DownloadStatus.pending ||
              d.status == DownloadStatus.paused,
        )
        .toList();
    emit(state.copyWith(downloads: updatedList));
  }

  /// Translates CEF interrupt reasons into error text.
  String _getInterruptReasonText(int reason) {
    switch (reason) {
      case 10:
        return 'File failed';
      case 20:
        return 'Network error';
      case 30:
        return 'Server error';
      case 40:
        return 'User error';
      default:
        return 'Network error';
    }
  }

  @override
  Future<void> close() async {
    _controllerMap.clear();
    return super.close();
  }
}
