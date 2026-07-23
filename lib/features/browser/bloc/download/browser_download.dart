import 'package:equatable/equatable.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class BrowserDownload extends Equatable {
  final int downloadId;
  final int browserId;
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

  const BrowserDownload({
    required this.downloadId,
    required this.browserId,
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
  });

  BrowserDownload copyWith({
    int? downloadId,
    int? browserId,
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
  }) {
    return BrowserDownload(
      downloadId: downloadId ?? this.downloadId,
      browserId: browserId ?? this.browserId,
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
    downloadId,
    browserId,
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
  ];
}
