import 'package:equatable/equatable.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
  interrupted,
}

class BrowserDownload extends Equatable {
  final int id; // Database Primary Key (0 if not persisted yet)
  final int downloadId; // Ephemeral CEF Download Identifier
  final String url;
  final String filename;
  final String destinationPath;
  final int receivedBytes;
  final int totalBytes;
  final int currentSpeed; // bytes per second
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;
  final DateTime startTimestamp;
  final DateTime? endTime;
  final String? errorMessage;
  final bool isPrivate;

  const BrowserDownload({
    this.id = 0,
    required this.downloadId,
    required this.url,
    required this.filename,
    required this.destinationPath,
    this.receivedBytes = 0,
    this.totalBytes = -1,
    this.currentSpeed = 0,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    required this.startTimestamp,
    this.endTime,
    this.errorMessage,
    this.isPrivate = false,
  });

  BrowserDownload copyWith({
    int? id,
    int? downloadId,
    String? url,
    String? filename,
    String? destinationPath,
    int? receivedBytes,
    int? totalBytes,
    int? currentSpeed,
    double? progress,
    DownloadStatus? status,
    DateTime? startTimestamp,
    DateTime? endTime,
    String? errorMessage,
    bool? isPrivate,
  }) {
    return BrowserDownload(
      id: id ?? this.id,
      downloadId: downloadId ?? this.downloadId,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      destinationPath: destinationPath ?? this.destinationPath,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTime: endTime ?? this.endTime,
      errorMessage: errorMessage ?? this.errorMessage,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  DownloadEntity toEntity() {
    return DownloadEntity(
      id: id,
      cefDownloadId: downloadId,
      url: url,
      fileName: filename,
      filePath: destinationPath,
      totalBytes: totalBytes,
      downloadedBytes: receivedBytes,
      statusIndex: status.index,
      createdAt: startTimestamp.millisecondsSinceEpoch,
      completedAt: endTime?.millisecondsSinceEpoch,
      errorMessage: errorMessage,
    );
  }

  factory BrowserDownload.fromEntity(DownloadEntity entity) {
    DownloadStatus status;
    if (entity.statusIndex >= 0 &&
        entity.statusIndex < DownloadStatus.values.length) {
      status = DownloadStatus.values[entity.statusIndex];
    } else {
      status = DownloadStatus.failed;
    }

    double progress = 0.0;
    if (entity.totalBytes > 0) {
      progress = (entity.downloadedBytes / entity.totalBytes).clamp(0.0, 1.0);
    }

    return BrowserDownload(
      id: entity.id,
      downloadId: entity.cefDownloadId,
      url: entity.url,
      filename: entity.fileName,
      destinationPath: entity.filePath,
      receivedBytes: entity.downloadedBytes,
      totalBytes: entity.totalBytes,
      currentSpeed: 0,
      progress: progress,
      status: status,
      startTimestamp: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
      endTime: entity.completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(entity.completedAt!)
          : null,
      errorMessage: entity.errorMessage,
    );
  }

  String get extensionLabel {
    final name = filename.isNotEmpty ? filename : url;
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx != -1 && dotIdx < name.length - 1) {
      final ext = name.substring(dotIdx).toLowerCase();
      // Remove query params if any
      final cleanExt = ext.split('?').first.split('#').first;
      if (cleanExt.length <= 6) {
        return cleanExt;
      }
    }
    return '.file';
  }

  String get domain {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isNotEmpty) {
        return uri.host;
      }
    } catch (_) {}
    return 'download';
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(count >= 10 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  String get formattedSize =>
      formatBytes(totalBytes > 0 ? totalBytes : receivedBytes);
  String get formattedReceived => formatBytes(receivedBytes);

  String get formattedSpeed {
    if (currentSpeed <= 0) return '0 B/s';
    return '${formatBytes(currentSpeed)}/s';
  }

  String get formattedTime {
    final targetTime = endTime ?? startTimestamp;
    final now = DateTime.now();
    final isToday =
        targetTime.year == now.year &&
        targetTime.month == now.month &&
        targetTime.day == now.day;
    final hour = targetTime.hour.toString().padLeft(2, '0');
    final minute = targetTime.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Today, $hour:$minute';
    }
    return '${targetTime.day}/${targetTime.month}, $hour:$minute';
  }

  String get metaText {
    switch (status) {
      case DownloadStatus.downloading:
      case DownloadStatus.paused:
      case DownloadStatus.pending:
        if (totalBytes > 0) {
          final pct = (progress * 100).toInt();
          return '$domain · $pct% of $formattedSize · $formattedSpeed';
        }
        return '$domain · $formattedReceived · $formattedSpeed';
      case DownloadStatus.interrupted:
        final pct = (progress * 100).toInt();
        return '$domain · Interrupted ($pct%) · $formattedReceived of $formattedSize';
      case DownloadStatus.completed:
        return '$domain · $formattedSize · $formattedTime';
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        final reason = errorMessage != null && errorMessage!.isNotEmpty
            ? errorMessage!
            : (status == DownloadStatus.cancelled
                  ? 'Cancelled'
                  : 'Network error');
        return '$domain · $reason';
    }
  }

  @override
  List<Object?> get props => [
    id,
    downloadId,
    url,
    filename,
    destinationPath,
    receivedBytes,
    totalBytes,
    currentSpeed,
    progress,
    status,
    startTimestamp,
    endTime,
    errorMessage,
    isPrivate,
  ];
}
