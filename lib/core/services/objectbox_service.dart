import 'dart:io';

import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/objectbox.g.dart';

class ObjectBoxService {
  static Store? _store;

  ObjectBoxService._();

  static Store get store {
    if (_store == null || _store!.isClosed()) {
      _initializeSync();
    }
    return _store!;
  }

  static void _initializeSync() {
    try {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw Exception('HOME environment variable is not set');
      }

      final storeDir = Directory('$home/${AppConstants.dbPath}');
      if (!storeDir.existsSync()) {
        storeDir.createSync(recursive: true);
      }

      _store = Store(getObjectBoxModel(), directory: storeDir.path);
    } catch (e, stackTrace) {
      AppLogger.i('Unable to synchronously initialize ObjectBox store: $e');
      AppLogger.i(stackTrace.toString());
      rethrow;
    }
  }

  static Future<Store> initialize() async {
    if (_store != null && !_store!.isClosed()) {
      return _store!;
    }
    _initializeSync();
    return _store!;
  }

  static void close() {
    if (_store != null && !_store!.isClosed()) {
      _store!.close();
    }
    _store = null;
  }
}
