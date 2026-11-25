import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';

/// Download history. Methods log failures and return a neutral value
/// (empty list, null, 0, false) instead of throwing, except
/// [getAllDownloads], whose failure the caller reports.
abstract class DownloadRepository {
  /// All downloads, newest first.
  Future<List<DownloadEntity>> getAllDownloads();

  Future<DownloadEntity?> getDownloadById(int id);

  Future<DownloadEntity?> getDownloadByCefId(int cefDownloadId);

  /// Inserts [entity] if its id is 0, otherwise updates it. Sets and returns
  /// the entity's id; returns 0 if saving failed.
  Future<int> saveDownload(DownloadEntity entity);

  /// Saves all [entities] in one transaction and returns their ids.
  Future<List<int>> saveAllDownloads(List<DownloadEntity> entities);

  /// Returns whether a record with [id] existed.
  Future<bool> deleteDownload(int id);

  Future<void> clearHistory();
}
