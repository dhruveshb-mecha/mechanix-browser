// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mechanix Browser';

  @override
  String get searchOrEnterAddress => 'Search or enter address';

  @override
  String get newTab => 'New tab';

  @override
  String get newPrivateTab => 'New Private Tab';

  @override
  String get history => 'History';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get downloads => 'Downloads';

  @override
  String get share => 'Share';

  @override
  String get desktopSite => 'Desktop site';

  @override
  String get settings => 'Settings';

  @override
  String get closeAll => 'Close all';

  @override
  String comingSoon(String feature) {
    return '$feature is Coming Soon';
  }

  @override
  String get workingHard => 'We\'re working hard to bring this feature to you.';

  @override
  String get privateTabOpened => 'Private tab opened';

  @override
  String get sharingPage => 'Sharing page...';

  @override
  String get pageBookmarked => 'Page bookmarked';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get desktopSiteEnabled => 'Desktop site enabled';

  @override
  String get desktopSiteDisabled => 'Desktop site disabled';

  @override
  String noRouteDefined(String routeName) {
    return 'No route defined for $routeName';
  }

  @override
  String get addFavorite => 'Add favourite';

  @override
  String get addFavoriteTitle => 'Add favorite';

  @override
  String get nameLabel => 'Name';

  @override
  String get favoriteNameHint => 'Favorite name';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'example.com';

  @override
  String get pleaseEnterUrl => 'Please enter a URL';

  @override
  String get pleaseEnterValidUrl => 'Please enter a valid URL';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get openPageFirst => 'Open a page first';

  @override
  String get currentPageBookmarked => 'Current page bookmarked';

  @override
  String get addCurrentPage => 'Add current page';

  @override
  String get favoritesSectionHeader => 'FAVORITES';

  @override
  String get noFavoritesSaved => 'No favorites saved';

  @override
  String get bookmarksSectionHeader => 'BOOKMARKS';

  @override
  String get noBookmarksSaved => 'No bookmarks saved';

  @override
  String get findInPage => 'Find in page';

  @override
  String get previousMatch => 'Previous match';

  @override
  String get nextMatch => 'Next match';

  @override
  String get siteCantBeReached => 'This site can\'t be reached';

  @override
  String checkTypoInUrl(String url) {
    return 'Check if there is a typo in $url.';
  }

  @override
  String get reload => 'Reload';

  @override
  String get clearFinished => 'Clear finished';

  @override
  String get openDownloadsFolder => 'Open Downloads Folder';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get noDownloadsDescription => 'Files downloaded from web pages will appear here.';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get failed => 'Failed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get networkError => 'Network error';

  @override
  String get serverError => 'Server error';

  @override
  String get userError => 'User error';

  @override
  String get fileFailed => 'File failed';

  @override
  String downloadingFile(String filename) {
    return 'Downloading $filename';
  }

  @override
  String get downloadingFiles => 'Downloading files...';

  @override
  String get clearAll => 'Clear all';

  @override
  String get delete => 'Delete';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';
}
