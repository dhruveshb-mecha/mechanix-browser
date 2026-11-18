import 'dart:io';

import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/data/bookmarks/bookmark_model.dart';
import 'package:path/path.dart' as p;

/// Owns the app's single [BookmarkModel], stored at
/// `$HOME/<AppConstants.profileDir>/<AppConstants.bookmarksFileName>`.
class BookmarkService {
  BookmarkService._();

  static BookmarkModel? _model;

  /// The loaded bookmarks. Call [initialize] first (main.dart does).
  static BookmarkModel get model =>
      _model ??
      (throw StateError('BookmarkService.initialize() was not called'));

  /// Loads the bookmarks file. Safe to call more than once.
  ///
  /// [homeDir] defaults to `$HOME`; tests pass a temporary directory.
  static Future<BookmarkModel> initialize({String? homeDir}) async {
    if (_model != null) return _model!;

    final home = homeDir ?? Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('HOME environment variable is not set');
    }
    final file = File(
      p.join(home, AppConstants.profileDir, AppConstants.bookmarksFileName),
    );
    return _model = await BookmarkModel.load(file);
  }

  /// Writes pending bookmark changes now (the model otherwise saves them a
  /// couple of seconds after a change).
  static Future<void> flush() async => _model?.flush();

  static Future<void> close() async {
    final model = _model;
    _model = null;
    await model?.close();
  }
}
