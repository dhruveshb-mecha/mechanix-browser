import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/models/page_transition.dart';

/// Browsing history, stored Chromium-style: one `urls` row per URL and one
/// `visits` row per visit. Reads return one [BrowserHistory] per visit
/// (its `id` is the visit id), newest first, leaving out visits that
/// redirected onward.
abstract class HistoryRepository {
  /// Visits, newest first.
  Future<List<BrowserHistory>> getHistory({int? limit});

  /// Visits whose URL or title contains [query] (ASCII case-insensitive),
  /// newest first. Empty for a blank query.
  Future<List<BrowserHistory>> searchHistory(String query, {int? limit});

  /// Records a visit to [url] and returns the new visit id.
  ///
  /// For a redirect, pass [PageTransition.redirect] and [fromVisit], the
  /// visit that redirected here. That visit is then no longer listed: history
  /// shows where a redirect chain ended, as in Chromium.
  Future<int> addVisit(
    String url, {
    PageTransition transition = PageTransition.link,
    int? fromVisit,
    DateTime? time,
  });

  /// Sets the page title stored for [url], if [url] is in history.
  Future<void> setTitle(String url, String title);

  /// Deletes a visit and the redirect sources that led to it; URLs go too
  /// once they have no visits left.
  Future<void> deleteVisit(int visitId);

  Future<void> clearHistory();

  /// Deletes visits before [cutoff] and URLs left without visits.
  /// Returns the number of visits deleted.
  Future<int> expireVisitsBefore(DateTime cutoff);
}
