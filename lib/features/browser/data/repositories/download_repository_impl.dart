import 'package:mechanix_browser/core/services/objectbox_service.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository.dart';
import 'package:mechanix_browser/objectbox.g.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  @override
  final Store store;

  @override
  late final Box<DownloadEntity> downloadBox;

  DownloadRepositoryImpl({Store? store})
    : store = store ?? ObjectBoxService.store {
    downloadBox = this.store.box<DownloadEntity>();
  }

  /// Fetches all stored download records ordered by creation timestamp descending (newest first).
  @override
  List<DownloadEntity> getAllDownloads() {
    try {
      final query =
          (downloadBox.query()
                ..order(DownloadEntity_.createdAt, flags: Order.descending))
              .build();
      try {
        return query.find();
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to load download history: $e',
        error: e,
        stack: stackTrace,
      );
      return [];
    }
  }

  /// Fetches a single download record by its ObjectBox primary key [id].
  @override
  DownloadEntity? getDownloadById(int id) {
    try {
      return downloadBox.get(id);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Error fetching download by id $id: $e',
        error: e,
        stack: stackTrace,
      );
      return null;
    }
  }

  /// Queries a download record by its ephemeral CEF download identifier [cefDownloadId].
  @override
  DownloadEntity? getDownloadByCefId(int cefDownloadId) {
    try {
      final query = downloadBox
          .query(DownloadEntity_.cefDownloadId.equals(cefDownloadId))
          .build();
      try {
        final results = query.find();
        return results.isNotEmpty ? results.first : null;
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Error fetching download by CEF id $cefDownloadId: $e',
        error: e,
        stack: stackTrace,
      );
      return null;
    }
  }

  /// Saves or updates a download entity in ObjectBox storage and returns assigned primary key.
  @override
  int saveDownload(DownloadEntity entity) {
    try {
      return downloadBox.put(entity);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to save download entity (id=${entity.id}): $e',
        error: e,
        stack: stackTrace,
      );
      return 0;
    }
  }

  /// Batch saves multiple download entities into ObjectBox in a single transaction.
  @override
  List<int> saveAllDownloads(List<DownloadEntity> entities) {
    try {
      return downloadBox.putMany(entities);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to batch save download entities: $e',
        error: e,
        stack: stackTrace,
      );
      return [];
    }
  }

  /// Deletes a download entity from ObjectBox storage by its primary key [id].
  @override
  bool deleteDownload(int id) {
    try {
      final removed = downloadBox.remove(id);
      if (!removed) {
        AppLogger.w(
          '[DownloadRepository] Attempted to delete record id=$id, but it was not found in ObjectBox',
        );
      }
      return removed;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to delete download entity $id: $e',
        error: e,
        stack: stackTrace,
      );
      return false;
    }
  }

  /// Removes all download entities from persistent storage.
  @override
  void clearHistory() {
    try {
      downloadBox.removeAll();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadRepository] Unable to clear download history: $e',
        error: e,
        stack: stackTrace,
      );
    }
  }

  /// Closes repository resources. Note: The underlying ObjectBox Store is managed globally by [ObjectBoxService].
  @override
  void close() {}
}
