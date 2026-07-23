import 'package:mechanix_browser/core/services/objectbox_service.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
import 'package:mechanix_browser/objectbox.g.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  @override
  final Store store;
  @override
  late final Box<BrowserHistory> historyBox;

  HistoryRepositoryImpl({Store? store})
    : store = store ?? ObjectBoxService.store {
    historyBox = this.store.box<BrowserHistory>();
  }

  @override
  List<BrowserHistory> getHistory() {
    try {
      final query =
          (historyBox.query()
                ..order(BrowserHistory_.timestamp, flags: Order.descending))
              .build();
      try {
        return query.find();
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      AppLogger.i('Unable to load history: $e');
      AppLogger.i(stackTrace.toString());
      rethrow;
    }
  }

  @override
  void saveHistory(BrowserHistory history) {
    try {
      historyBox.put(history);
    } catch (e, stackTrace) {
      AppLogger.i('Unable to save history: $e');
      AppLogger.i(stackTrace.toString());
      rethrow;
    }
  }

  @override
  void deleteHistory(int id) {
    try {
      historyBox.remove(id);
    } catch (e, stackTrace) {
      AppLogger.i('Unable to delete history item: $e');
      AppLogger.i(stackTrace.toString());
      rethrow;
    }
  }

  @override
  void clearHistory() {
    try {
      historyBox.removeAll();
    } catch (e, stackTrace) {
      AppLogger.i('Unable to clear history: $e');
      AppLogger.i(stackTrace.toString());
      rethrow;
    }
  }

  @override
  List<BrowserHistory> searchHistory(String queryText) {
    try {
      if (queryText.trim().isEmpty) return [];
      final query = (historyBox.query(
        BrowserHistory_.title
            .contains(queryText, caseSensitive: false)
            .or(BrowserHistory_.url.contains(queryText, caseSensitive: false)),
      )..order(BrowserHistory_.timestamp, flags: Order.descending)).build();
      try {
        return query.find();
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      AppLogger.i('Unable to search history: $e');
      AppLogger.i(stackTrace.toString());
      return [];
    }
  }

  @override
  void close() {
    // No-op as the store lifecycle is managed by ObjectBoxService
  }
}
