import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/objectbox.g.dart';

abstract class DownloadRepository {
  Store get store;

  Box<DownloadEntity> get downloadBox;

  List<DownloadEntity> getAllDownloads();

  DownloadEntity? getDownloadById(int id);

  DownloadEntity? getDownloadByCefId(int cefDownloadId);

  int saveDownload(DownloadEntity entity);

  List<int> saveAllDownloads(List<DownloadEntity> entities);

  bool deleteDownload(int id);

  void clearHistory();

  void close();
}
