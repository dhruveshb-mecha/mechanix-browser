import 'package:intl/intl.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';

class HistoryGroup {
  final String title;
  final List<BrowserHistory> items;

  const HistoryGroup({required this.title, required this.items});
}

class HistoryDateGrouper {
  /// Groups [entries] into date-based sections.
  /// An optional [now] parameter can be provided for deterministic testing.
  static List<HistoryGroup> groupHistory(
    List<BrowserHistory> entries, {
    DateTime? now,
  }) {
    try {
      if (entries.isEmpty) return const [];

      final referenceNow = now ?? DateTime.now();

      // Local calendar midnight for Today
      final todayMidnight = DateTime(
        referenceNow.year,
        referenceNow.month,
        referenceNow.day,
      );

      // Local calendar midnight for Yesterday
      final yesterdayMidnight = DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day - 1,
      );

      // Start of current week (Monday at 00:00:00)
      final startOfWeek = DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day - (todayMidnight.weekday - 1),
      );

      // Start of current month (1st of current month at 00:00:00)
      final startOfMonth = DateTime(todayMidnight.year, todayMidnight.month, 1);

      final todayItems = <BrowserHistory>[];
      final yesterdayItems = <BrowserHistory>[];
      final thisWeekItems = <BrowserHistory>[];
      final thisMonthItems = <BrowserHistory>[];
      final previousMonthsMap = <String, List<BrowserHistory>>{};
      final previousMonthsTitles = <String, String>{};
      final previousMonthsKeys = <String>[];

      // NOTE: The `entries` list retrieved from the database is already
      // pre-sorted in descending order (newest first).
      // Iterating sequentially naturally preserves this chronological order.
      for (final item in entries) {
        // Convert the millisecond timestamp directly to a DateTime object.
        // Since we generate and save timestamps in Dart, they are always in milliseconds.
        final itemDateTime = DateTime.fromMillisecondsSinceEpoch(
          item.timestamp,
        );

        // Strip out time-of-day components (hours, minutes, seconds) to get a clean calendar day at midnight.
        final itemDate = DateTime(
          itemDateTime.year,
          itemDateTime.month,
          itemDateTime.day,
        );

        // Check if the history item belongs to "Today".
        if (itemDate.isAtSameMomentAs(todayMidnight) ||
            itemDate.isAfter(todayMidnight)) {
          todayItems.add(item);
        }
        // Check if the history item belongs to "Yesterday".
        else if (itemDate.isAtSameMomentAs(yesterdayMidnight) ||
            (itemDate.isAfter(yesterdayMidnight) &&
                itemDate.isBefore(todayMidnight))) {
          yesterdayItems.add(item);
        }
        // Check if the history item belongs to "This Week" (excluding Today/Yesterday, which are caught above).
        else if (itemDate.isAtSameMomentAs(startOfWeek) ||
            itemDate.isAfter(startOfWeek)) {
          thisWeekItems.add(item);
        }
        // Check if the history item belongs to "This Month" (excluding Today/Yesterday/This Week, caught above).
        else if (itemDate.isAtSameMomentAs(startOfMonth) ||
            itemDate.isAfter(startOfMonth)) {
          thisMonthItems.add(item);
        }
        // Otherwise, group the history item under its respective previous month (e.g. "June 2026").
        else {
          // Create a unique key for the month (e.g., "2026-06").
          final key =
              '${itemDateTime.year}-${itemDateTime.month.toString().padLeft(2, '0')}';
          if (!previousMonthsMap.containsKey(key)) {
            previousMonthsMap[key] = [];
            // Appending to `previousMonthsKeys` sequentially preserves the
            // descending chronological order of the months.
            previousMonthsKeys.add(key);
            // Human-readable title for the month group (e.g., "June 2026").
            previousMonthsTitles[key] = DateFormat(
              'MMMM yyyy',
            ).format(itemDateTime);
          }
          previousMonthsMap[key]!.add(item);
        }
      }

      final groups = <HistoryGroup>[];

      if (todayItems.isNotEmpty) {
        groups.add(HistoryGroup(title: 'Today', items: todayItems));
      }
      if (yesterdayItems.isNotEmpty) {
        groups.add(HistoryGroup(title: 'Yesterday', items: yesterdayItems));
      }
      if (thisWeekItems.isNotEmpty) {
        groups.add(HistoryGroup(title: 'This Week', items: thisWeekItems));
      }
      if (thisMonthItems.isNotEmpty) {
        groups.add(HistoryGroup(title: 'This Month', items: thisMonthItems));
      }

      // Since `previousMonthsKeys` is populated in order of encounter (newest to oldest),
      // we can iterate over the keys directly without any sorting.
      for (final key in previousMonthsKeys) {
        final items = previousMonthsMap[key]!;
        if (items.isNotEmpty) {
          groups.add(
            HistoryGroup(title: previousMonthsTitles[key]!, items: items),
          );
        }
      }

      return groups;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to group history entries by date',
        error: e,
        stack: stackTrace,
      );
      return const [];
    }
  }
}
