import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:webview_cef/webview_cef.dart';

/// Manages active WebViewController mappings, raw CEF download IDs,
/// and deferred WebViewController disposal for closed tabs running active background downloads.
class DownloadControllerManager {
  /// Maps composite download ID -> active [WebViewController] across all open/hidden tabs.
  final Map<int, WebViewController> _controllerMap = {};

  /// Maps composite download ID -> raw native CEF engine integer download ID.
  final Map<int, int> _rawCefIdMap = {};

  /// Tracks webview controllers of closed tabs whose downloads are still actively running in the background.
  final Set<WebViewController> _pendingDisposeControllers = {};

  /// Registers or updates the active controller and CEF download ID mapping for a composite download ID.
  void registerSession(
    int compositeId,
    int rawCefId,
    WebViewController controller,
  ) {
    cleanStaleControllers();
    _controllerMap[compositeId] = controller;
    _rawCefIdMap[compositeId] = rawCefId;
  }

  /// Retrieves the active [WebViewController] associated with [compositeId].
  WebViewController? getController(int compositeId) =>
      _controllerMap[compositeId];

  /// Retrieves the raw native CEF download ID associated with [compositeId], falling back to [fallbackId] if absent.
  int getRawCefId(int compositeId, {int? fallbackId}) =>
      _rawCefIdMap[compositeId] ?? fallbackId ?? compositeId;

  /// Removes session mappings for [compositeId].
  void removeSession(int compositeId) {
    _controllerMap.remove(compositeId);
    _rawCefIdMap.remove(compositeId);
  }

  /// Registers a [WebViewController] whose tab was closed to defer disposal until all its active downloads finish.
  void registerPendingDisposeController(WebViewController controller) {
    _pendingDisposeControllers.add(controller);
    AppLogger.i(
      '[DownloadControllerManager] Registered background download controller for deferred disposal upon download completion',
    );
  }

  /// Checks if a [WebViewController] is actively handling any in-progress downloads.
  bool isControllerActive(WebViewController controller) {
    return _controllerMap.values.contains(controller);
  }

  /// Disposes of a pending background controller if all its active downloads have reached terminal status.
  void checkAndDisposePendingController(
    WebViewController controller,
    List<BrowserDownload> downloads,
  ) {
    if (!_pendingDisposeControllers.contains(controller)) return;

    final hasRemainingDownloads = downloads.any(
      (d) =>
          (d.status == DownloadStatus.downloading ||
              d.status == DownloadStatus.pending) &&
          _controllerMap[d.downloadId] == controller,
    );

    if (!hasRemainingDownloads) {
      AppLogger.i(
        '[DownloadControllerManager] All background downloads finished for closed tab. Disposing WebViewController now.',
      );
      _pendingDisposeControllers.remove(controller);
      try {
        controller.dispose();
      } catch (e) {
        AppLogger.e('Error disposing background download controller: $e');
      }
    }
  }

  /// Removes disposed or inactive [WebViewController] references from memory map.
  void cleanStaleControllers() {
    _controllerMap.removeWhere((key, controller) {
      try {
        return !controller.value;
      } catch (_) {
        return true;
      }
    });
  }

  /// Clears all session mappings and disposes pending controllers on BLoC teardown.
  void close() {
    for (final controller in _pendingDisposeControllers) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    _pendingDisposeControllers.clear();
    _controllerMap.clear();
    _rawCefIdMap.clear();
  }
}
