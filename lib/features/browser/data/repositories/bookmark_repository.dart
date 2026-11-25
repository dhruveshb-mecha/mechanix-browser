import 'package:mechanix_browser/core/services/bookmark_service.dart';
import 'package:mechanix_browser/features/browser/data/bookmarks/bookmark_model.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';

enum BookmarkSortBy { score, timestamp }

/// Bookmarks and favorites, kept in the Chromium-style bookmark tree
/// ([BookmarkModel]): favorites are the bookmark bar, bookmarks are "Other
/// bookmarks" (and "Mobile bookmarks"), including any in folders.
///
/// The tree lives in memory, so every method is synchronous; the model saves
/// changes to the `Bookmarks` file shortly after they're made.
class BookmarkRepository {
  BookmarkRepository({BookmarkModel? model})
    : _model = model ?? BookmarkService.model;

  final BookmarkModel _model;

  // Bookmark fields with no place in Chromium's node format go in its
  // `meta_info` map, as strings.
  static const _iconUrlKey = 'icon_url';
  static const _scoreKey = 'score';

  /// Adds a bookmark/favorite, or updates the entry with the same URL and
  /// type. Sets and returns [bookmark]'s id.
  int addOrUpdate(Bookmark bookmark) {
    final existing = _nodesFor(bookmark.url, bookmark.type).firstOrNull;
    final node =
        existing ??
        _model.addUrl(
          _rootsFor(bookmark.type).first,
          title: bookmark.title ?? '',
          url: bookmark.url,
          dateAdded: DateTime.fromMillisecondsSinceEpoch(bookmark.timestamp),
        );
    _model.setTitle(node, bookmark.title ?? '');
    _model.setMetaInfo(node, _iconUrlKey, bookmark.iconUrl);
    _model.setMetaInfo(
      node,
      _scoreKey,
      bookmark.score == 0 ? null : bookmark.score.toString(),
    );
    return bookmark.id = node.id;
  }

  /// Removes the bookmark/favorite with [id]; false if there is none.
  bool remove(int id) {
    final node = _model.nodeById(id);
    if (node == null || !node.isUrl) return false;
    _model.remove(node);
    return true;
  }

  /// Removes every entry of [type] for [url]; false if there were none.
  bool removeByUrlAndType(String url, BookmarkType type) {
    final nodes = _nodesFor(url, type);
    nodes.forEach(_model.remove);
    return nodes.isNotEmpty;
  }

  /// Whether [url] is bookmarked (`BookmarkType.bookmark`).
  bool isBookmarked(String url) => isSaved(url, BookmarkType.bookmark);

  /// Whether [url] is saved with [type].
  bool isSaved(String url, BookmarkType type) =>
      _nodesFor(url, type).isNotEmpty;

  /// All bookmarks (`BookmarkType.bookmark`), sorted by score or timestamp.
  List<Bookmark> getBookmarks({
    BookmarkSortBy sortBy = BookmarkSortBy.timestamp,
    bool descending = true,
  }) => queryBookmarks(
    type: BookmarkType.bookmark,
    sortBy: sortBy,
    descending: descending,
  );

  /// All favorites (`BookmarkType.favorite`), sorted by score or timestamp.
  List<Bookmark> getFavorites({
    BookmarkSortBy sortBy = BookmarkSortBy.timestamp,
    bool descending = true,
  }) => queryBookmarks(
    type: BookmarkType.favorite,
    sortBy: sortBy,
    descending: descending,
  );

  /// Entries of [type] (all if null), sorted by [sortBy].
  List<Bookmark> queryBookmarks({
    BookmarkType? type,
    BookmarkSortBy sortBy = BookmarkSortBy.timestamp,
    bool descending = true,
  }) {
    final types = type == null ? BookmarkType.values : [type];
    final bookmarks = [
      for (final t in types)
        for (final root in _rootsFor(t))
          for (final node in root.subtree)
            if (node.isUrl) _toBookmark(node, t),
    ];
    num key(Bookmark b) =>
        sortBy == BookmarkSortBy.score ? b.score : b.timestamp;
    bookmarks.sort((a, b) {
      final byKey = key(a).compareTo(key(b));
      return byKey != 0 ? byKey : a.id.compareTo(b.id);
    });
    return descending ? bookmarks.reversed.toList() : bookmarks;
  }

  List<BookmarkNode> _rootsFor(BookmarkType type) => switch (type) {
    BookmarkType.favorite => [_model.bookmarkBar],
    BookmarkType.bookmark => [_model.other, _model.synced],
  };

  BookmarkType _typeOf(BookmarkNode node) {
    var root = node;
    while (root.parent != null) {
      root = root.parent!;
    }
    return identical(root, _model.bookmarkBar)
        ? BookmarkType.favorite
        : BookmarkType.bookmark;
  }

  List<BookmarkNode> _nodesFor(String url, BookmarkType type) => [
    for (final node in _model.nodesForUrl(url))
      if (_typeOf(node) == type) node,
  ];

  Bookmark _toBookmark(BookmarkNode node, BookmarkType type) => Bookmark.create(
    id: node.id,
    url: node.url!,
    title: node.title.isEmpty ? null : node.title,
    iconUrl: node.metaInfo[_iconUrlKey],
    timestamp: node.dateAdded.millisecondsSinceEpoch,
    type: type,
    score: double.tryParse(node.metaInfo[_scoreKey] ?? '') ?? 0,
  );
}
