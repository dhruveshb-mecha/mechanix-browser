import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/objectbox.g.dart';

enum BookmarkSortBy { score, timestamp }

class BookmarkRepository {
  final Store store;
  late final Box<Bookmark> bookmarkBox;

  BookmarkRepository._(this.store) {
    bookmarkBox = store.box<Bookmark>();
  }

  static Future<BookmarkRepository> create({Store? store}) async {
    try {
      if (store != null) {
        return BookmarkRepository._(store);
      }

      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw Exception('HOME environment variable is not set');
      }

      final storeDir = Directory('$home/${AppConstants.dbPath}');
      if (!await storeDir.exists()) {
        await storeDir.create(recursive: true);
      }

      final newStore = await openStore(directory: storeDir.path);
      return BookmarkRepository._(newStore);
    } catch (e, stackTrace) {
      debugPrint('Unable to initialize bookmark storage: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
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
      debugPrint('Unable to save bookmark: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  /// Removes a bookmark item by its ID.
  bool remove(int id) {
    try {
      return bookmarkBox.remove(id);
    } catch (e, stackTrace) {
      debugPrint('Unable to remove bookmark by id ($id): $e');
      debugPrint(stackTrace.toString());
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
      debugPrint(
        'Unable to remove bookmark by url ($url) and type ($type): $e',
      );
      debugPrint(stackTrace.toString());
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
      debugPrint('Unable to check if url is saved: $e');
      debugPrint(stackTrace.toString());
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
      debugPrint('Unable to query bookmarks: $e');
      debugPrint(stackTrace.toString());
      return [];
    }
  }

  void close() {
    store.close();
  }
}
