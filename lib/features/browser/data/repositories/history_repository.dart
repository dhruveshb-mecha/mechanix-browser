import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/objectbox.g.dart';

class HistoryRepository {
  final Store store;
  late final Box<BrowserHistory> historyBox;

  HistoryRepository._(this.store) {
    historyBox = store.box<BrowserHistory>();
  }

  static Future<HistoryRepository> create() async {
    try {
      final home = Platform.environment['HOME'];

      if (home == null || home.isEmpty) {
        throw Exception('HOME environment variable is not set');
      }

      final storeDir = Directory('$home/${AppConstants.dbPath}');

      if (!await storeDir.exists()) {
        await storeDir.create(recursive: true);
      }

      final store = await openStore(directory: storeDir.path);

      return HistoryRepository._(store);
    } catch (e, stackTrace) {
      debugPrint('Unable to initialize history storage: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  List<BrowserHistory> getHistory() {
    try {
      final query =
          (historyBox.query()
                ..order(BrowserHistory_.timestamp, flags: Order.descending))
              .build();
      final results = query.find();
      query.close();
      return results;
    } catch (e, stackTrace) {
      debugPrint('Unable to load history: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  void saveHistory(BrowserHistory history) {
    // TODO: later we need to implement this
    // try {
    //   historyBox.put(history);
    // } catch (e, stackTrace) {
    //   debugPrint('Unable to save history: $e');
    //   debugPrint(stackTrace.toString());
    //   rethrow;
    // }
  }

  void clearHistory() {
    // TODO: later we need to implement this
    // try {
    //   historyBox.removeAll();
    // } catch (e, stackTrace) {
    //   debugPrint('Unable to clear history: $e');
    //   debugPrint(stackTrace.toString());
    //   rethrow;
    // }
  }

  List<BrowserHistory> searchHistory(String queryText) {
    try {
      if (queryText.trim().isEmpty) return [];
      final query = (historyBox.query(
        BrowserHistory_.title
            .contains(queryText, caseSensitive: false)
            .or(BrowserHistory_.url.contains(queryText, caseSensitive: false)),
      )..order(BrowserHistory_.timestamp, flags: Order.descending)).build();
      final results = query.find();
      query.close();
      return results;
    } catch (e, stackTrace) {
      debugPrint('Unable to search history: $e');
      debugPrint(stackTrace.toString());
      return [];
    }
  }

  void close() {
    store.close();
  }
}
