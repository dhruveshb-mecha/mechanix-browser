class AppConstants {
  static const String homepageUrl = 'about:blank';
  static const String searchUrlPrefix = 'https://www.google.com/search?q=';
  static const String defaultUserAgent = 'test/userAgent';
  static const String defaultScheme = 'https://';

  /// Browser data directory, relative to $HOME (Chromium's profile dir).
  static const String profileDir = '.config/mechanix_apps/browser';

  /// SQLite database (history, downloads, tabs) in [profileDir].
  static const String databaseFileName = 'browser.sqlite';

  /// Bookmarks JSON file in [profileDir].
  static const String bookmarksFileName = 'Bookmarks';

  /// ObjectBox store; goes away once everything is on drift.
  static const String dbPath = '$profileDir/objectbox';

  /// History visits older than this are deleted (Chromium keeps 90 days).
  static const Duration historyRetention = Duration(days: 90);
  static const int maxFavoritesCount = 5;
  static const Duration bottomBarAutoHideDuration = Duration(seconds: 2);
}

class AppImages {
  static const String logo = 'assets/images/logo.png';
  static const String incognitoImage = 'assets/images/incognito.png';
}
