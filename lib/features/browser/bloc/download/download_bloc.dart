import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_service.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_session_manager.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository.dart';
import 'package:webview_cef/webview_cef.dart';

part 'download_event.dart';
part 'download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final DownloadRepository? repository;

  final DownloadControllerManager _controllerManager =
      DownloadControllerManager();

  /// Maps composite download ID -> timestamp of last ObjectBox write for I/O throttling.
  final Map<int, DateTime> _lastDbSaveMap = {};

  /// Tracks ObjectBox primary keys (`id`) reserved for retried/restarted downloads to avoid duplicate DB records.
  final Set<int> _pendingRetryRecordIds = {};

  DownloadBloc({this.repository}) : super(DownloadState.initial()) {
    on<DownloadInitializeRequested>(_onInitialize);
    on<DownloadBeforeStarted>(_onBeforeStarted);
    on<DownloadUpdatedEvent>(_onUpdated);
    on<DownloadCancelRequested>(_onCancelRequested);
    on<DownloadPauseRequested>(_onPauseRequested);
    on<DownloadResumeRequested>(_onResumeRequested);
    on<DownloadRemoveRequested>(_onRemoveRequested);
    on<DownloadRetryRequested>(_onRetryRequested);
    on<DownloadRestartRequested>(_onRestartRequested);
    on<DownloadClearCompletedRequested>(_onClearCompleted);
  }

  /// Combines the WebViewController instance hash and raw CEF integer download ID into a globally unique composite ID.
  static int getCompositeDownloadId(
    WebViewController controller,
    int rawCefDownloadId,
  ) {
    final controllerHash = controller.hashCode.abs() % 100000;
    return controllerHash * 100000 + (rawCefDownloadId % 100000);
  }

  /// Registers a closed tab's WebViewController to defer its disposal until active downloads complete.
  void registerPendingDisposeController(WebViewController controller) {
    _controllerManager.registerPendingDisposeController(controller);
  }

  /// Returns `true` if [controller] is actively streaming an in-progress download.
  bool isControllerActive(WebViewController controller) {
    return _controllerManager.isControllerActive(controller);
  }

  int _findMatchingRetryIndex({
    required int compositeId,
    required int rawCefId,
    required String sanitizedName,
    required String url,
  }) {
    if (_pendingRetryRecordIds.isEmpty) return -1;

    int index = state.downloads.indexWhere(
      (d) =>
          _pendingRetryRecordIds.contains(d.id) &&
          (d.downloadId == compositeId || d.downloadId == rawCefId),
    );
    if (index != -1) return index;

    index = state.downloads.indexWhere(
      (d) =>
          _pendingRetryRecordIds.contains(d.id) &&
          (d.filename == sanitizedName ||
              d.destinationPath.endsWith(sanitizedName)),
    );
    if (index != -1) return index;

    return state.downloads.indexWhere(
      (d) => _pendingRetryRecordIds.contains(d.id) && d.url == url,
    );
  }

  /// Persists [download] to ObjectBox and returns the entity with its assigned primary key.
  BrowserDownload _saveDownloadToRepo(BrowserDownload download) {
    if (download.isPrivate) return download;

    final repo = repository;
    if (repo == null) return download;

    final dbId = repo.saveDownload(download.toEntity());
    return download.id != dbId ? download.copyWith(id: dbId) : download;
  }

  /// Updates or inserts a download item in BLoC state list and emits the updated state.
  void _updateStateWithDownload(
    Emitter<DownloadState> emit,
    BrowserDownload updatedDownload, {
    int existingIndex = -1,
  }) {
    final updatedList = List<BrowserDownload>.from(state.downloads);
    final targetIndex = existingIndex != -1
        ? existingIndex
        : updatedList.indexWhere(
            (d) =>
                (updatedDownload.id > 0 && d.id == updatedDownload.id) ||
                (d.downloadId != 0 &&
                    d.downloadId == updatedDownload.downloadId),
          );

    if (targetIndex != -1) {
      updatedList[targetIndex] = updatedDownload;
    } else {
      updatedList.removeWhere(
        (d) => (d.id == 0 && d.downloadId == updatedDownload.downloadId),
      );
      updatedList.insert(0, updatedDownload);
    }

    emit(
      state.copyWith(
        downloads: updatedList,
        lastStartedOrUpdated: updatedDownload,
      ),
    );
  }

  /// Restores download history on app startup and converts incomplete transfers from crashed sessions to `interrupted`.
  Future<void> _onInitialize(
    DownloadInitializeRequested event,
    Emitter<DownloadState> emit,
  ) async {
    final repo = repository;
    if (repo == null) return;

    try {
      final entities = repo.getAllDownloads();
      final loadedDownloads = <BrowserDownload>[];

      for (final entity in entities) {
        if (entity.statusIndex == DownloadStatus.downloading.index ||
            entity.statusIndex == DownloadStatus.pending.index ||
            entity.statusIndex == DownloadStatus.paused.index) {
          entity.statusIndex = DownloadStatus.interrupted.index;
          entity.errorMessage = 'Interrupted';
          repo.saveDownload(entity);
        }
        loadedDownloads.add(BrowserDownload.fromEntity(entity));
      }

      emit(state.copyWith(downloads: loadedDownloads, clearError: true));
      AppLogger.i(
        '[DownloadBloc] Restored ${loadedDownloads.length} download records from database',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Failed to initialize download history: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.initializationFailed));
    }
  }

  /// Handles `OnBeforeDownload` native CEF triggers, generating unique target paths and starting byte streaming.
  Future<void> _onBeforeStarted(
    DownloadBeforeStarted event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      // Register CEF controller session and compute composite ID
      final rawCefId = event.downloadId;
      final compositeId = getCompositeDownloadId(event.controller, rawCefId);

      _controllerManager.registerSession(
        compositeId,
        rawCefId,
        event.controller,
      );

      // Resolve downloads directory and sanitize target filename
      final dirPath = await DownloadService.getDownloadsDirectoryPath();
      final sanitizedName = DownloadService.sanitizeFilename(
        event.suggestedName,
        event.url,
      );

      // Reuse existing DB record ID if matching pending retry request exists
      final existingIndex = _findMatchingRetryIndex(
        compositeId: compositeId,
        rawCefId: rawCefId,
        sanitizedName: sanitizedName,
        url: event.url,
      );

      int targetDbId = 0;
      if (existingIndex != -1) {
        targetDbId = state.downloads[existingIndex].id;
        _pendingRetryRecordIds.remove(targetDbId);
      }

      // Collect active destination paths to avoid duplicate filename collisions
      final activePaths = state.downloads
          .where(
            (d) => d.status == DownloadStatus.downloading && d.id != targetDbId,
          )
          .map((d) => d.destinationPath)
          .toSet();

      // Resolve destination path (reusing for retries vs generating unique path)
      final String destPath;
      if (targetDbId > 0 &&
          existingIndex != -1 &&
          state.downloads[existingIndex].destinationPath.isNotEmpty) {
        destPath = state.downloads[existingIndex].destinationPath;
      } else {
        destPath = DownloadService.getUniqueDestinationPath(
          dirPath,
          sanitizedName,
          activePaths: activePaths,
        );
      }

      final extractedFilename = destPath.split('/').last.split('\\').last;

      // Construct model entity, persist to database, and update BLoC state
      var newDownload = BrowserDownload(
        id: targetDbId,
        downloadId: compositeId,
        url: event.url,
        filename: extractedFilename,
        destinationPath: destPath,
        receivedBytes: 0,
        totalBytes: event.totalBytes,
        currentSpeed: 0,
        progress: 0.0,
        status: DownloadStatus.downloading,
        startTimestamp: DateTime.now(),
        isPrivate: event.isPrivate,
      );

      newDownload = _saveDownloadToRepo(newDownload);
      _updateStateWithDownload(emit, newDownload, existingIndex: existingIndex);

      AppLogger.i(
        '[DownloadBloc] Starting download: ${newDownload.filename} (id=${newDownload.id}, path=$destPath)',
      );

      // Instruct native CEF webview controller to start writing byte stream
      await event.controller.continueDownload(
        rawCefId,
        destPath,
        showDialog: false,
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error starting download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.startFailed));
    }
  }

  int _findDownloadIndex(int downloadId) {
    return state.downloads.indexWhere(
      (d) =>
          (d.id > 0 && d.id == downloadId) ||
          (d.downloadId != 0 && d.downloadId == downloadId),
    );
  }

  /// Processes progress ticks from CEF, updating speed, progress, and throttled DB persistence.
  void _onUpdated(DownloadUpdatedEvent event, Emitter<DownloadState> emit) {
    // Match composite ID to active download in state
    final compositeId = getCompositeDownloadId(
      event.controller,
      event.downloadId,
    );

    final index = state.downloads.indexWhere(
      (d) => d.downloadId == compositeId,
    );
    if (index == -1) return;

    final existing = state.downloads[index];

    // Map native CEF status flags to domain DownloadStatus
    DownloadStatus status = DownloadStatus.downloading;
    String? errorMsg;

    if (existing.status == DownloadStatus.paused &&
        !event.isComplete &&
        !event.isCanceled &&
        !event.isInterrupted) {
      status = DownloadStatus.paused;
    } else if (event.isComplete) {
      status = DownloadStatus.completed;
    } else if (event.isCanceled) {
      status = DownloadStatus.cancelled;
      errorMsg = 'Cancelled';
    } else if (event.isInterrupted) {
      status = DownloadStatus.failed;
      errorMsg = _getInterruptReasonText(event.interruptReason);
    }

    final progress = event.totalBytes > 0
        ? (event.receivedBytes / event.totalBytes).clamp(0.0, 1.0)
        : 0.0;

    final filename = event.fullPath.isNotEmpty
        ? event.fullPath.split('/').last.split('\\').last
        : existing.filename;

    final isTerminal =
        status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled ||
        status == DownloadStatus.paused;

    BrowserDownload updatedDownload = existing.copyWith(
      filename: filename,
      destinationPath: event.fullPath.isNotEmpty
          ? event.fullPath
          : existing.destinationPath,
      receivedBytes: event.receivedBytes,
      totalBytes: event.totalBytes > 0 ? event.totalBytes : existing.totalBytes,
      currentSpeed: event.currentSpeed,
      progress: progress,
      status: status,
      endTime:
          (status == DownloadStatus.completed ||
              status == DownloadStatus.failed ||
              status == DownloadStatus.cancelled)
          ? DateTime.now()
          : existing.endTime,
      errorMessage: errorMsg ?? existing.errorMessage,
    );

    // Throttled persistence — save to database at most once per 1000ms or on terminal status
    final now = DateTime.now();
    final lastSave = _lastDbSaveMap[compositeId];

    if (isTerminal ||
        lastSave == null ||
        now.difference(lastSave).inMilliseconds >= 1000) {
      updatedDownload = _saveDownloadToRepo(updatedDownload);
      _lastDbSaveMap[compositeId] = now;
    }

    _updateStateWithDownload(emit, updatedDownload, existingIndex: index);

    // Clean up session tracking and dispose idle background webviews on terminal status
    if (isTerminal && status != DownloadStatus.paused) {
      _controllerManager.removeSession(compositeId);
      _lastDbSaveMap.remove(compositeId);
      _controllerManager.checkAndDisposePendingController(
        event.controller,
        state.downloads,
      );
    }
  }

  /// Cancels an active download stream, purges session mappings, and disposes background controllers if idle.
  Future<void> _onCancelRequested(
    DownloadCancelRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final index = _findDownloadIndex(event.downloadId);
      if (index == -1) return;

      final item = state.downloads[index];
      final controller = _controllerManager.getController(item.downloadId);
      final rawCefId = _controllerManager.getRawCefId(item.downloadId);

      if (controller != null) {
        await controller.cancelDownload(rawCefId);
      }
      _controllerManager.removeSession(item.downloadId);

      var updated = item.copyWith(
        status: DownloadStatus.cancelled,
        errorMessage: 'Cancelled',
        endTime: DateTime.now(),
      );

      if (updated.id > 0) {
        updated = _saveDownloadToRepo(updated);
      }

      _updateStateWithDownload(emit, updated, existingIndex: index);

      if (controller != null) {
        _controllerManager.checkAndDisposePendingController(
          controller,
          state.downloads,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error cancelling download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.cancelFailed));
    }
  }

  /// Pauses an active CEF download stream and updates DB record status to `paused`.
  Future<void> _onPauseRequested(
    DownloadPauseRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final index = _findDownloadIndex(event.downloadId);
      if (index == -1) return;

      final item = state.downloads[index];
      final controller = _controllerManager.getController(item.downloadId);
      final rawCefId = _controllerManager.getRawCefId(item.downloadId);

      if (controller != null) {
        await controller.pauseDownload(rawCefId);
      }

      var updated = item.copyWith(status: DownloadStatus.paused);
      if (updated.id > 0) {
        updated = _saveDownloadToRepo(updated);
      }

      _updateStateWithDownload(emit, updated, existingIndex: index);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error pausing download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.pauseFailed));
    }
  }

  /// Resumes a paused stream, or re-initiates the download via `loadUrl` if the tab session was closed.
  Future<void> _onResumeRequested(
    DownloadResumeRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final index = _findDownloadIndex(event.downloadId);
      if (index == -1) return;

      final download = state.downloads[index];
      final controller =
          event.controller ??
          _controllerManager.getController(download.downloadId);
      final rawCefId = _controllerManager.getRawCefId(download.downloadId);

      if (download.status == DownloadStatus.paused &&
          controller != null &&
          controller.value) {
        await controller.resumeDownload(rawCefId);
        var updated = download.copyWith(status: DownloadStatus.downloading);
        if (updated.id > 0) {
          updated = _saveDownloadToRepo(updated);
        }
        _updateStateWithDownload(emit, updated, existingIndex: index);
      } else if (controller != null && controller.value) {
        // Fallback: If live CEF stream was lost, reload source URL to re-trigger download
        if (download.id > 0) {
          _pendingRetryRecordIds.add(download.id);
        }
        await controller.loadUrl(download.url);
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error resuming download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.resumeFailed));
    }
  }

  /// Removes a download record from state/ObjectBox, optionally deleting physical target and `.crdownload` files from disk.
  Future<void> _onRemoveRequested(
    DownloadRemoveRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final index = _findDownloadIndex(event.downloadId);

      if (index != -1) {
        final item = state.downloads[index];
        final targetRecordId = item.id != 0 ? item.id : event.downloadId;

        // Optionally delete physical target file and partial buffer (.crdownload) from disk
        if (event.deleteFile && item.destinationPath.isNotEmpty) {
          try {
            await DownloadService.deleteFileFromDisk(item.destinationPath);
          } catch (e, stackTrace) {
            AppLogger.e(
              '[DownloadBloc] Error deleting download file: $e',
              error: e,
              stack: stackTrace,
            );
          }
        }

        // Delete persistent record from ObjectBox database repository
        final repo = repository;
        if (repo != null && targetRecordId > 0) {
          repo.deleteDownload(targetRecordId);
        }

        final controller = _controllerManager.getController(item.downloadId);
        final rawCefId = _controllerManager.getRawCefId(item.downloadId);

        // Cancel active native CEF stream if transfer is running
        if ((item.status == DownloadStatus.downloading ||
                item.status == DownloadStatus.pending ||
                item.status == DownloadStatus.paused) &&
            controller != null) {
          try {
            await controller.cancelDownload(rawCefId);
          } catch (_) {}
        }

        // Clean up session manager tracking and throttle maps
        _controllerManager.removeSession(item.downloadId);
        _lastDbSaveMap.remove(item.downloadId);

        if (controller != null) {
          _controllerManager.checkAndDisposePendingController(
            controller,
            state.downloads,
          );
        }
      } else {
        final repo = repository;
        if (repo != null && event.downloadId > 0) {
          repo.deleteDownload(event.downloadId);
        }
      }

      // Filter out removed item and emit updated state to UI listeners
      final updatedList = List<BrowserDownload>.from(state.downloads)
        ..removeWhere(
          (d) =>
              d.id == event.downloadId ||
              (d.id == 0 && d.downloadId == event.downloadId),
        );

      emit(state.copyWith(downloads: updatedList));
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error removing download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.removeFailed));
    }
  }

  /// Retries a failed download by reloading source URL in webview while preserving its DB record ID.
  Future<void> _onRetryRequested(
    DownloadRetryRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      // Find matching download in active state list by ID, composite ID, or URL
      final index = state.downloads.indexWhere(
        (d) =>
            (event.download.id > 0 && d.id == event.download.id) ||
            (d.downloadId != 0 && d.downloadId == event.download.downloadId) ||
            (d.url == event.download.url),
      );
      final item = index != -1 ? state.downloads[index] : event.download;

      // Register primary key in pending retry set so existing DB ID is reused
      if (item.id > 0) {
        _pendingRetryRecordIds.add(item.id);
      }

      // Reload URL in webview controller to re-trigger download stream
      final controller =
          event.controller ?? _controllerManager.getController(item.downloadId);
      if (controller != null && controller.value) {
        await controller.loadUrl(item.url);
      } else {
        AppLogger.w(
          '[DownloadBloc] Cannot retry download ${event.download.filename}: WebViewController is unavailable',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error retrying download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.retryFailed));
    }
  }

  /// Restarts a download from byte 0, purging any partial `.crdownload` file buffer on disk.
  Future<void> _onRestartRequested(
    DownloadRestartRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      if (event.download.destinationPath.isNotEmpty) {
        try {
          await DownloadService.deleteFileFromDisk(
            event.download.destinationPath,
          );
        } catch (e, stackTrace) {
          AppLogger.e(
            '[DownloadBloc] Error deleting download file: $e',
            error: e,
            stack: stackTrace,
          );
        }
      }

      if (event.download.id > 0) {
        _pendingRetryRecordIds.add(event.download.id);
        final repo = repository;
        if (repo != null) {
          final entity = event.download.toEntity();
          entity.downloadedBytes = 0;
          entity.statusIndex = DownloadStatus.pending.index;
          repo.saveDownload(entity);
        }
      }

      final controller =
          event.controller ??
          _controllerManager.getController(event.download.downloadId);
      if (controller != null && controller.value) {
        await controller.loadUrl(event.download.url);
      } else {
        AppLogger.w(
          '[DownloadBloc] Cannot restart download ${event.download.filename}: WebViewController is unavailable',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error restarting download: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.restartFailed));
    }
  }

  /// Clears finished downloads (`completed`, `cancelled`, `failed`) from state and database.
  Future<void> _onClearCompleted(
    DownloadClearCompletedRequested event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final toRemove = state.downloads
          .where(
            (d) =>
                d.status == DownloadStatus.completed ||
                d.status == DownloadStatus.cancelled ||
                d.status == DownloadStatus.failed,
          )
          .toList();

      final repo = repository;
      for (final item in toRemove) {
        if (event.deleteFiles && item.destinationPath.isNotEmpty) {
          try {
            await DownloadService.deleteFileFromDisk(item.destinationPath);
          } catch (e, stackTrace) {
            AppLogger.e(
              '[DownloadBloc] Error deleting download file: $e',
              error: e,
              stack: stackTrace,
            );
          }
        }
        if (repo != null && item.id > 0) {
          repo.deleteDownload(item.id);
        }
        _controllerManager.removeSession(item.downloadId);
        _lastDbSaveMap.remove(item.downloadId);
      }

      final toRemoveSet = toRemove.toSet();
      final updatedList = state.downloads
          .where((d) => !toRemoveSet.contains(d))
          .toList();

      emit(state.copyWith(downloads: updatedList));
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error clearing completed downloads: $e',
        error: e,
        stack: stackTrace,
      );
      emit(state.copyWith(errorType: DownloadErrorType.clearFailed));
    }
  }

  /// Translates CEF interrupt reason codes into user-friendly error strings.
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

  /// Cleans up resources when BLoC is disposed, marking active downloads as cancelled.
  @override
  Future<void> close() async {
    try {
      final repo = repository;
      if (repo != null) {
        for (final d in state.downloads) {
          if ((d.status == DownloadStatus.downloading ||
                  d.status == DownloadStatus.pending ||
                  d.status == DownloadStatus.paused) &&
              d.id > 0) {
            final entity = d.toEntity();
            entity.statusIndex = DownloadStatus.cancelled.index;
            entity.errorMessage = 'Cancelled';
            if (d.destinationPath.isNotEmpty) {
              await DownloadService.deleteFileFromDisk(d.destinationPath);
            }
            repo.saveDownload(entity);
          }
        }
      }

      _controllerManager.close();
      _lastDbSaveMap.clear();
      _pendingRetryRecordIds.clear();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadBloc] Error closing DownloadBloc: $e',
        error: e,
        stack: stackTrace,
      );
    }
    return super.close();
  }
}
