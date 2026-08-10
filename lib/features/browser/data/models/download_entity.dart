import 'package:objectbox/objectbox.dart';

@Entity()
class DownloadEntity {
  @Id()
  int id = 0;

  int cefDownloadId;
  String url;
  String fileName;
  String filePath;
  int totalBytes;
  int downloadedBytes;
  int statusIndex;
  int createdAt;
  int? completedAt;
  String? errorMessage;

  DownloadEntity({
    this.id = 0,
    required this.cefDownloadId,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.totalBytes = -1,
    this.downloadedBytes = 0,
    required this.statusIndex,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });
}
