import 'dart:io';

import 'package:mechanix_browser/core/utils/app_logger.dart';

class DownloadService {
  static Future<String> getDownloadsDirectoryPath() async {
    final home = Platform.environment['HOME'];
    final downloadsPath = home != null && home.isNotEmpty
        ? '$home/Downloads'
        : '${Directory.current.path}/Downloads';

    final dir = Directory(downloadsPath);
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (e) {
        AppLogger.i('Failed to create downloads directory: $e');
      }
    }

    return downloadsPath;
  }

  static String sanitizeFilename(String suggestedName, String url) {
    String name = suggestedName.trim();
    if (name.isEmpty) {
      try {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          name = Uri.decodeComponent(segments.last);
        }
      } catch (_) {}
    }

    if (name.isEmpty) {
      name = 'downloaded_file';
    }

    // Remove path traversal and invalid path characters
    name = name.replaceAll(RegExp(r'[\/\x00-\x1F\x7F<>:"\\|?*]'), '_');
    while (name.contains('..')) {
      name = name.replaceAll('..', '_');
    }
    name = name.trim();
    if (name.isEmpty || name == '.' || name == '..') {
      name = 'downloaded_file';
    }

    return name;
  }

  static String getUniqueDestinationPath(String dirPath, String filename) {
    final separator = Platform.pathSeparator;
    final fullPath = '$dirPath$separator$filename';
    final targetFile = File(fullPath);

    if (!targetFile.existsSync()) {
      return fullPath;
    }

    final dotIdx = filename.lastIndexOf('.');
    String nameStem = filename;
    String extension = '';
    if (dotIdx != -1 && dotIdx > 0) {
      nameStem = filename.substring(0, dotIdx);
      extension = filename.substring(dotIdx);
    }

    int counter = 1;
    while (true) {
      final newFilename = '$nameStem ($counter)$extension';
      final newPath = '$dirPath$separator$newFilename';
      if (!File(newPath).existsSync()) {
        return newPath;
      }
      counter++;
    }
  }

  static Future<void> openDownloadedFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return;

    try {
      if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      }
    } catch (e) {
      AppLogger.i('Failed to open file: $e');
    }
  }

  static Future<void> openDownloadFolder(String filePath) async {
    final file = File(filePath);
    final folderPath = file.existsSync()
        ? file.parent.path
        : Directory(filePath).path;

    try {
      if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [folderPath]);
      }
    } catch (e) {
      AppLogger.i('Failed to open folder: $e');
    }
  }
}
