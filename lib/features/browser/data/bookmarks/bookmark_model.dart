import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/important_file_writer.dart';

enum BookmarkNodeType { url, folder }

/// A bookmark (url node) or folder in the bookmark tree.
///
/// Read-only outside this file: change nodes through [BookmarkModel] so every
/// edit is saved.
class BookmarkNode {
  BookmarkNode._({
    required this.id,
    required this.type,
    required this._title,
    this._url,
    required this.dateAdded,
    Map<String, String>? metaInfo,
    this.isPermanent = false,
  }) : _metaInfo = {...?metaInfo};

  final int id;
  final BookmarkNodeType type;
  String _title;
  String? _url;
  final DateTime dateAdded;
  final Map<String, String> _metaInfo;
  final List<BookmarkNode> _children = [];
  BookmarkNode? _parent;

  /// True for the fixed roots, which can't be removed or renamed.
  final bool isPermanent;

  String get title => _title;

  /// The bookmarked URL; null for folders.
  String? get url => _url;

  /// Extra string values, e.g. an icon URL (Chromium's `meta_info`).
  Map<String, String> get metaInfo => Map.unmodifiable(_metaInfo);
  List<BookmarkNode> get children => List.unmodifiable(_children);
  BookmarkNode? get parent => _parent;

  bool get isUrl => type == BookmarkNodeType.url;
  bool get isFolder => type == BookmarkNodeType.folder;

  /// This node and everything below it, parents before children.
  Iterable<BookmarkNode> get subtree sync* {
    yield this;
    for (final child in _children) {
      yield* child.subtree;
    }
  }

  // Chromium stores times as microseconds since 1601-01-01 UTC, as strings.
  static const _windowsEpochOffsetMicros = 11644473600000000;

  Map<String, Object> _toJson() => {
    if (isFolder) 'children': [for (final c in _children) c._toJson()],
    'date_added': (dateAdded.microsecondsSinceEpoch + _windowsEpochOffsetMicros)
        .toString(),
    'id': id.toString(),
    if (_metaInfo.isNotEmpty) 'meta_info': _metaInfo,
    'name': _title,
    'type': type.name,
    if (isUrl) 'url': _url!,
  };

  /// Returns null for a node that can't be used (unknown type, url node
  /// without a URL, bad id).
  static BookmarkNode? _fromJson(
    Map<String, Object?> json, {
    bool root = false,
  }) {
    final id = int.tryParse('${json['id']}');
    final type = switch (json['type']) {
      'url' => BookmarkNodeType.url,
      'folder' => BookmarkNodeType.folder,
      _ => null,
    };
    final url = json['url'];
    if (id == null || type == null) return null;
    if (type == BookmarkNodeType.url && url is! String) return null;

    final micros = int.tryParse('${json['date_added']}');
    final node = BookmarkNode._(
      id: id,
      type: type,
      title: json['name'] is String ? json['name'] as String : '',
      url: url is String ? url : null,
      dateAdded: micros == null
          ? DateTime.now().toUtc()
          : DateTime.fromMicrosecondsSinceEpoch(
              micros - _windowsEpochOffsetMicros,
              isUtc: true,
            ),
      metaInfo: {
        if (json['meta_info'] case final Map<String, Object?> meta)
          for (final MapEntry(:key, :value) in meta.entries)
            if (value is String) key: value,
      },
      isPermanent: root,
    );
    final children = json['children'];
    if (node.isFolder && children is List) {
      for (final childJson in children.whereType<Map<String, Object?>>()) {
        final child = _fromJson(childJson);
        if (child == null) continue;
        child._parent = node;
        node._children.add(child);
      }
    }
    return node;
  }

  @override
  String toString() =>
      'BookmarkNode($id, ${type.name}, "$title"${isUrl ? ', $url' : ''})';
}

/// The bookmark tree, held in memory and saved as a JSON `Bookmarks` file in
/// Chromium's layout (`roots` → `bookmark_bar` / `other` / `synced`).
///
/// Like Chromium: every change is applied in memory at once, and the whole
/// tree is written [defaultSaveDelay] after the first change of a burst,
/// atomically, keeping the previous file as `Bookmarks.bak` the first time
/// it is replaced in a session.
class BookmarkModel {
  BookmarkModel._(this._writer, this.bookmarkBar, this.other, this.synced) {
    for (final root in roots) {
      for (final node in root.subtree) {
        _index(node);
        _nextId = max(_nextId, node.id + 1);
      }
    }
  }

  /// Chromium's `BookmarkStorage::kSaveDelay`.
  static const defaultSaveDelay = Duration(milliseconds: 2500);
  static const _version = 1;

  /// Loads the tree from [file].
  ///
  /// A missing file gives empty roots (nothing is written until the first
  /// change). An unreadable file is kept as `<file>.corrupt`, and the `.bak`
  /// backup is used instead if it can be read.
  static Future<BookmarkModel> load(
    File file, {
    Duration saveDelay = defaultSaveDelay,
  }) async {
    final writer = ImportantFileWriter(
      file,
      commitInterval: saveDelay,
      backupBeforeFirstWrite: true,
    );

    List<BookmarkNode>? roots;
    var restoredFromBackup = false;
    if (await file.exists()) {
      try {
        roots = _decode(await file.readAsString());
      } on FormatException catch (e) {
        AppLogger.w('Unreadable bookmarks file ${file.path}', error: e);
        await file.copy('${file.path}.corrupt');
        try {
          if (await writer.backupFile.exists()) {
            roots = _decode(await writer.backupFile.readAsString());
            restoredFromBackup = true;
          }
        } on FormatException catch (e) {
          AppLogger.w('Unreadable bookmarks backup', error: e);
        }
      }
    }

    DateTime now() => DateTime.now().toUtc();
    BookmarkNode emptyRoot(int id, String title) => BookmarkNode._(
      id: id,
      type: BookmarkNodeType.folder,
      title: title,
      dateAdded: now(),
      isPermanent: true,
    );
    roots ??= [
      emptyRoot(1, 'Bookmarks bar'),
      emptyRoot(2, 'Other bookmarks'),
      emptyRoot(3, 'Mobile bookmarks'),
    ];

    final model = BookmarkModel._(writer, roots[0], roots[1], roots[2]);
    if (restoredFromBackup) model._scheduleSave();
    return model;
  }

  static List<BookmarkNode> _decode(String contents) {
    final json = jsonDecode(contents);
    if (json is! Map<String, Object?> || json['version'] != _version) {
      throw const FormatException('Not a version 1 bookmarks file');
    }
    final roots = json['roots'];
    return [
      for (final key in ['bookmark_bar', 'other', 'synced'])
        switch (roots is Map ? roots[key] : null) {
          final Map<String, Object?> r =>
            BookmarkNode._fromJson(r, root: true) ??
                (throw FormatException('Bad "$key" root')),
          _ => throw FormatException('Missing "$key" root'),
        },
    ];
  }

  String _encode() => const JsonEncoder.withIndent('   ').convert({
    'roots': {
      'bookmark_bar': bookmarkBar._toJson(),
      'other': other._toJson(),
      'synced': synced._toJson(),
    },
    'version': _version,
  });

  final ImportantFileWriter _writer;
  final _changes = StreamController<void>.broadcast();
  final _byId = <int, BookmarkNode>{};
  final _byUrl = <String, List<BookmarkNode>>{};
  int _nextId = 1;

  /// Chromium's "Bookmarks bar" root.
  final BookmarkNode bookmarkBar;

  /// Chromium's "Other bookmarks" root.
  final BookmarkNode other;

  /// Chromium's "Mobile bookmarks" root (`synced` in the file).
  final BookmarkNode synced;

  List<BookmarkNode> get roots => [bookmarkBar, other, synced];

  /// Emits after every change to the tree.
  Stream<void> get changes => _changes.stream;

  BookmarkNode? nodeById(int id) => _byId[id];

  /// Url nodes for [url], in no particular order.
  List<BookmarkNode> nodesForUrl(String url) =>
      List.unmodifiable(_byUrl[url] ?? const []);

  bool isBookmarked(String url) => _byUrl[url]?.isNotEmpty ?? false;

  /// Whether a save is waiting for the save delay.
  bool get hasPendingSave => _writer.hasPendingWrite;

  BookmarkNode addUrl(
    BookmarkNode parent, {
    required String title,
    required String url,
    int? index,
    DateTime? dateAdded,
    Map<String, String>? metaInfo,
  }) => _add(
    parent,
    index,
    BookmarkNode._(
      id: _nextId++,
      type: BookmarkNodeType.url,
      title: title,
      url: url,
      dateAdded: (dateAdded ?? DateTime.now()).toUtc(),
      metaInfo: metaInfo,
    ),
  );

  BookmarkNode addFolder(BookmarkNode parent, String title, {int? index}) =>
      _add(
        parent,
        index,
        BookmarkNode._(
          id: _nextId++,
          type: BookmarkNodeType.folder,
          title: title,
          dateAdded: DateTime.now().toUtc(),
        ),
      );

  void setTitle(BookmarkNode node, String title) {
    _checkOwned(node);
    if (node.isPermanent) {
      throw ArgumentError('Permanent folders keep their title');
    }
    if (node._title == title) return;
    node._title = title;
    _changed();
  }

  void setUrl(BookmarkNode node, String url) {
    _checkOwned(node);
    if (!node.isUrl) throw ArgumentError('Only url nodes have a URL');
    if (node._url == url) return;
    _unindexUrl(node);
    node._url = url;
    _byUrl.putIfAbsent(url, () => []).add(node);
    _changed();
  }

  /// Sets [key] in the node's meta info, or removes it when [value] is null.
  void setMetaInfo(BookmarkNode node, String key, String? value) {
    _checkOwned(node);
    if (node._metaInfo[key] == value) return;
    if (value == null) {
      node._metaInfo.remove(key);
    } else {
      node._metaInfo[key] = value;
    }
    _changed();
  }

  /// Removes [node] and, for folders, everything in it.
  void remove(BookmarkNode node) {
    _checkOwned(node);
    if (node.isPermanent) {
      throw ArgumentError('Permanent folders can\'t be removed');
    }
    node._parent!._children.remove(node);
    node._parent = null;
    for (final n in node.subtree) {
      _byId.remove(n.id);
      _unindexUrl(n);
    }
    _changed();
  }

  /// Writes any pending change now (e.g. before the app exits).
  Future<void> flush() => _writer.flush();

  /// Flushes and stops change notifications.
  Future<void> close() async {
    await flush();
    await _changes.close();
  }

  BookmarkNode _add(BookmarkNode parent, int? index, BookmarkNode node) {
    _checkOwned(parent);
    if (!parent.isFolder) throw ArgumentError('$parent is not a folder');
    final at = index ?? parent._children.length;
    RangeError.checkValueInInterval(at, 0, parent._children.length);
    parent._children.insert(at, node);
    node._parent = parent;
    _index(node);
    _changed();
    return node;
  }

  void _index(BookmarkNode node) {
    _byId[node.id] = node;
    if (node.isUrl) _byUrl.putIfAbsent(node.url!, () => []).add(node);
  }

  void _unindexUrl(BookmarkNode node) {
    if (!node.isUrl) return;
    final list = _byUrl[node.url!];
    list?.remove(node);
    if (list != null && list.isEmpty) _byUrl.remove(node.url!);
  }

  void _checkOwned(BookmarkNode node) {
    if (!identical(_byId[node.id], node)) {
      throw ArgumentError('$node is not in this model');
    }
  }

  void _changed() {
    _scheduleSave();
    if (!_changes.isClosed) _changes.add(null);
  }

  void _scheduleSave() => _writer.scheduleWrite(_encode);
}
