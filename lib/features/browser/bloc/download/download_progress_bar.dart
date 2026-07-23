import 'package:flutter/material.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';

class DownloadProgressBar extends StatelessWidget {
  final BrowserDownload download;
  final double height;

  const DownloadProgressBar({
    super.key,
    required this.download,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed =
        download.status == DownloadStatus.failed ||
        download.status == DownloadStatus.cancelled;

    final barColor = isFailed
        ? const Color(0xFFE54D42)
        : const Color(0xFF5B96F7);
    final backgroundColor = const Color(0xFF2C2C2E);

    final progressValue = download.progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: backgroundColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: isFailed
                ? 0.45
                : (progressValue <= 0 ? 0.05 : progressValue),
            child: Container(color: barColor),
          ),
        ),
      ),
    );
  }
}
