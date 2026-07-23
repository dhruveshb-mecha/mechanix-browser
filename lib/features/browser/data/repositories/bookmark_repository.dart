import 'package:mechanix_browser/core/services/objectbox_service.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/objectbox.g.dart';

enum BookmarkSortBy { score, timestamp }

class BookmarkRepository {
  final Store store;
  late final Box<Bookmark> bookmarkBox;

  BookmarkRepository({Store? store}) : store = store ?? ObjectBoxService.store {
    bookmarkBox = this.store.box<Bookmark>();
  }

  /// Adds a new bookmark/favorite or updates an existing entry with the same URL and type.
  /// Prevents duplicate entries for the same URL and type combination.
  int addOrUpdate(Bookmark bookmark) {
    try {
      final existingQuery = bookmarkBox
          .query(
            Bookmark_.url
                .equals(bookmark.url)
                .and(Bookmark_.typeString.equals(bookmark.type.name)),
          )
          .build();
      final existing = existingQuery.findFirst();
      existingQuery.close();

      if (existing != null) {
        bookmark.id = existing.id;
      }

      return bookmarkBox.put(bookmark);
    } catch (e, stackTrace) {
      AppLogger.i('Unable to save bookmark: $e');
      AppLogger.i(stackTrace.toString());
      rethrow;
    }
  }

  /// Removes a bookmark item by its ID.
  bool remove(int id) {
    try {
      return bookmarkBox.remove(id);
    } catch (e, stackTrace) {
      AppLogger.i('Unable to remove bookmark by id ($id): $e');
      AppLogger.i(stackTrace.toString());
      return false;
    }
  }

  /// Removes a bookmark item by URL and type.
  bool removeByUrlAndType(String url, BookmarkType type) {
    try {
      final query = bookmarkBox
          .query(
            Bookmark_.url
                .equals(url)
                .and(Bookmark_.typeString.equals(type.name)),
          )
          .build();
      final ids = query.findIds();
      query.close();

      if (ids.isEmpty) return false;
      return bookmarkBox.removeMany(ids) == ids.length;
    } catch (e, stackTrace) {
      AppLogger.i(
        'Unable to remove bookmark by url ($url) and type ($type): $e',
      );
      AppLogger.i(stackTrace.toString());
      return false;
    }
  }

  /// Checks whether a URL is bookmarked (`BookmarkType.bookmark`).
  bool isBookmarked(String url) {
    return isSaved(url, BookmarkType.bookmark);
  }

  /// Checks whether a URL is saved with the specified type.
  bool isSaved(String url, BookmarkType type) {
    try {
      final query = bookmarkBox
          .query(
            Bookmark_.url
                .equals(url)
                .and(Bookmark_.typeString.equals(type.name)),
          )
          .build();
      final count = query.count();
      query.close();
      return count > 0;
    } catch (e, stackTrace) {
      AppLogger.i('Unable to check if url is saved: $e');
      AppLogger.i(stackTrace.toString());
      return false;
    }
  }

  /// Fetches all bookmarks (`BookmarkType.bookmark`), sorted by score or timestamp.
  List<Bookmark> getBookmarks({
    BookmarkSortBy sortBy = BookmarkSortBy.timestamp,
    bool descending = true,
  }) {
    return queryBookmarks(
      type: BookmarkType.bookmark,
      sortBy: sortBy,
      descending: descending,
    );
  }

  /// Fetches all favorites (`BookmarkType.favorite`), sorted by score or timestamp.
  List<Bookmark> getFavorites({
    BookmarkSortBy sortBy = BookmarkSortBy.timestamp,
    bool descending = true,
  }) {
    return queryBookmarks(
      type: BookmarkType.favorite,
      sortBy: sortBy,
      descending: descending,
    );
  }

  /// Queries items based on optional [type], sorted by [sortBy] and [descending].
  List<Bookmark> queryBookmarks({
    BookmarkType? type,
    BookmarkSortBy sortBy = BookmarkSortBy.timestamp,
    bool descending = true,
  }) {
    try {
      Condition<Bookmark>? condition;
      if (type != null) {
        condition = Bookmark_.typeString.equals(type.name);
      }

      final queryBuilder = bookmarkBox.query(condition);

      final flags = descending ? Order.descending : 0;
      if (sortBy == BookmarkSortBy.score) {
        queryBuilder.order(Bookmark_.score, flags: flags);
      } else {
        queryBuilder.order(Bookmark_.timestamp, flags: flags);
      }

      final query = queryBuilder.build();
      final results = query.find();
      query.close();
      return results;
    } catch (e, stackTrace) {
      AppLogger.i('Unable to query bookmarks: $e');
      AppLogger.i(stackTrace.toString());
      return [];
    }
  }

  void close() {
    // No-op as the store lifecycle is managed by ObjectBoxService
  }
}
