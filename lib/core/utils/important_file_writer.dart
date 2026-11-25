import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;

/// Writes a file so that a crash or power loss leaves either the old contents
/// or the new ones, never a half-written file. Modelled on Chromium's
/// `ImportantFileWriter`.
///
/// Changes are batched: [scheduleWrite] starts a [commitInterval] timer if
/// none is running, and the latest serializer is used when it fires. A burst
/// of edits therefore costs one write, at most [commitInterval] after the
/// first edit.
class ImportantFileWriter {
  ImportantFileWriter(
    this.file, {
    this.commitInterval = const Duration(seconds: 10),
    this.backupBeforeFirstWrite = false,
  });

  final File file;
  final Duration commitInterval;

  /// Copy the existing file to `<file>.bak` once, before this writer first
  /// replaces it (Chromium does this for Bookmarks).
  final bool backupBeforeFirstWrite;

  String Function()? _serializer;
  Timer? _timer;
  Future<void> _lastWrite = Future.value();
  bool _backupDone = false;

  File get backupFile => File('${file.path}.bak');

  bool get hasPendingWrite => _timer != null;

  /// Writes the result of [serializer] after [commitInterval], unless a write
  /// is already scheduled, in which case that write will use [serializer].
  void scheduleWrite(String Function() serializer) {
    _serializer = serializer;
    _timer ??= Timer(commitInterval, () {
      _write(_takeScheduled()).catchError((Object e, StackTrace s) {
        AppLogger.e('Failed to write ${file.path}', error: e, stack: s);
      });
    });
  }

  /// Performs a scheduled write now, if any, and waits for all writes so far
  /// to reach the disk. Errors from the flushed write are rethrown.
  Future<void> flush() {
    if (_timer != null) return _write(_takeScheduled());
    return _lastWrite;
  }

  /// Writes [data] now, replacing any scheduled write.
  Future<void> writeNow(String data) {
    _timer?.cancel();
    _timer = null;
    _serializer = null;
    return _write(data);
  }

  String _takeScheduled() {
    _timer?.cancel();
    _timer = null;
    final serializer = _serializer!;
    _serializer = null;
    return serializer();
  }

  /// Writes are queued so they never overlap and land in order.
  Future<void> _write(String data) {
    final write = _lastWrite.catchError((_) {}).then((_) async {
      if (backupBeforeFirstWrite && !_backupDone) {
        _backupDone = true;
        if (await file.exists()) await file.copy(backupFile.path);
      }
      await writeFileAtomically(file, data);
    });
    _lastWrite = write;
    return write;
  }

  /// Writes [data] to a temporary file in the same directory, flushes it to
  /// disk, then renames it over [file]. The rename is atomic on POSIX.
  static Future<void> writeFileAtomically(File file, String data) async {
    final dir = file.parent;
    await dir.create(recursive: true);
    final suffix = Random().nextInt(1 << 32).toRadixString(36);
    final tmp = File(p.join(dir.path, '.${p.basename(file.path)}.$suffix'));
    try {
      final raf = await tmp.open(mode: FileMode.writeOnly);
      try {
        await raf.writeString(data);
        await raf.flush(); // fsync
      } finally {
        await raf.close();
      }
      await tmp.rename(file.path);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
  }
}
