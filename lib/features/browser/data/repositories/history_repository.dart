import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/objectbox.g.dart';

abstract class HistoryRepository {
  Store get store;

  Box<BrowserHistory> get historyBox;

  List<BrowserHistory> getHistory();

  void saveHistory(BrowserHistory history);

  void deleteHistory(int id);

  void clearHistory();

  List<BrowserHistory> searchHistory(String queryText);

  void close();
}
