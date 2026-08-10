import 'dart:io';

import 'package:mechanix_browser/core/utils/app_logger.dart';

class DownloadService {
  /// Returns the absolute path to the user's Downloads directory.
  static Future<String> getDownloadsDirectoryPath() async {
    try {
      final home = Platform.environment['HOME'];
      final downloadsPath = home != null && home.isNotEmpty
          ? '$home/Downloads'
          : '${Directory.current.path}/Downloads';

      final dir = Directory(downloadsPath);
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
          AppLogger.i(
            '[DownloadService] Created missing downloads directory: $downloadsPath',
          );
        } catch (e, stackTrace) {
          AppLogger.e(
            '[DownloadService] Failed to create downloads directory: $e',
            error: e,
            stack: stackTrace,
          );
        }
      }

      return downloadsPath;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadService] Error resolving downloads directory path: $e',
        error: e,
        stack: stackTrace,
      );
      return '${Directory.current.path}/Downloads';
    }
  }

  /// Sanitizes a suggested file name to prevent path traversal exploits and illegal path characters.
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

  /// Generates a non-conflicting destination file path in [dirPath].
  ///
  /// Checks if the target path or its partial `.crdownload` counterpart already exists on disk
  /// or in [activePaths]. Appends `(1)`, `(2)`, etc. before the extension until an available path is found.
  static String getUniqueDestinationPath(
    String dirPath,
    String filename, {
    Set<String>? activePaths,
  }) {
    final separator = Platform.pathSeparator;
    final fullPath = '$dirPath$separator$filename';

    bool isPathInUse(String p) {
      if (activePaths != null && activePaths.contains(p)) return true;
      if (File(p).existsSync()) return true;
      if (File('$p.crdownload').existsSync()) return true;
      return false;
    }

    if (!isPathInUse(fullPath)) {
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
      if (!isPathInUse(newPath)) {
        AppLogger.i(
          '[DownloadService] Filename collision detected. Resolved unique path: $newPath',
        );
        return newPath;
      }
      counter++;
    }
  }

  /// Returns potential disk paths for [filePath], including its Chromium `.crdownload` partial buffer counterpart.
  static List<String> getPossibleFilePaths(String filePath) {
    if (filePath.isEmpty) return [];
    final set = <String>{filePath};

    if (filePath.endsWith('.crdownload')) {
      final base = filePath.substring(
        0,
        filePath.length - '.crdownload'.length,
      );
      if (base.isNotEmpty) {
        set.add(base);
      }
    } else {
      set.add('$filePath.crdownload');
    }

    return set.toList();
  }

  /// Checks disk for existing bytes associated with [filePath] (checking target path and `.crdownload`).
  static int getActualDownloadedBytes(String filePath) {
    if (filePath.isEmpty) return 0;
    try {
      final possiblePaths = getPossibleFilePaths(filePath);
      for (final p in possiblePaths) {
        final f = File(p);
        if (f.existsSync()) {
          final len = f.lengthSync();
          if (len > 0) return len;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadService] Error reading file length for $filePath: $e',
        error: e,
        stack: stackTrace,
      );
    }
    return 0;
  }

  /// Deletes target file and any partial Chromium buffer files (`.crdownload`) from disk.
  static Future<bool> deleteFileFromDisk(String filePath) async {
    if (filePath.isEmpty) return false;
    bool deleted = false;
    try {
      final possiblePaths = getPossibleFilePaths(filePath);
      for (final p in possiblePaths) {
        final f = File(p);
        if (await f.exists()) {
          await f.delete();
          deleted = true;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadService] Error deleting file from disk ($filePath): $e',
        error: e,
        stack: stackTrace,
      );
    }
    return deleted;
  }

  /// Opens a downloaded file using the default desktop OS viewer (`xdg-open`, `open`, `explorer`).
  static Future<void> openDownloadedFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      AppLogger.w(
        '[DownloadService] Cannot open file: file does not exist at $filePath',
      );
      return;
    }

    try {
      AppLogger.i('[DownloadService] Opening downloaded file: $filePath');
      if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadService] Failed to open file $filePath: $e',
        error: e,
        stack: stackTrace,
      );
    }
  }

  /// Opens the folder containing [filePath] in the native OS file manager (`xdg-open`, `open`, `explorer`).
  static Future<void> openDownloadFolder(String filePath) async {
    final file = File(filePath);
    final folderPath = file.existsSync()
        ? file.parent.path
        : Directory(filePath).path;

    if (!Directory(folderPath).existsSync()) {
      AppLogger.w(
        '[DownloadService] Cannot open download folder: folder does not exist at $folderPath',
      );
      return;
    }

    try {
      AppLogger.i('[DownloadService] Opening download folder: $folderPath');
      if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[DownloadService] Failed to open folder $folderPath: $e',
        error: e,
        stack: stackTrace,
      );
    }
  }
}
