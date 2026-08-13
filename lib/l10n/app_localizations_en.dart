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
  String appTitlePrivate(String title) {
    return '$title (Private)';
  }

  @override
  String get privateBrowsing => 'Private Browsing';

  @override
  String get privateBrowsingDescription => 'Pages you view in private tabs won\'t be saved in your history, cookie store, or search history after you close all of your private tabs. Bookmarks and downloads will still be kept.';

  @override
  String get privateTabs => 'Private Tabs';

  @override
  String get normalTabs => 'Normal Tabs';

  @override
  String get noPrivateTabs => 'No Private Tabs';

  @override
  String get noTabs => 'No Tabs';

  @override
  String get switchToNormalTabs => 'Switch to Normal Tabs';

  @override
  String get switchToPrivateTabs => 'Switch to Private Tabs';

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
  String get developerTools => 'Developer tools';

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
  String get clearDownloadsTitle => 'Clear Downloads';

  @override
  String get clearDownloadsDialogContent => 'Do you want to clear download records from history or also delete downloaded files from disk?';

  @override
  String get clearHistoryOnly => 'Clear History Only';

  @override
  String get deleteFilesAndHistory => 'Delete Files & History';

  @override
  String get removeDownloadTitle => 'Remove Download';

  @override
  String removeDownloadDialogContent(String filename) {
    return 'Do you want to remove \"$filename\" from history or delete the downloaded file from disk?';
  }

  @override
  String get removeHistoryOnly => 'Remove History Only';

  @override
  String get deleteFileAndHistory => 'Delete File & History';

  @override
  String get resumeOrRetry => 'Resume / Retry';

  @override
  String get remove => 'Remove';

  @override
  String get pending => 'Pending';

  @override
  String get interrupted => 'Interrupted';

  @override
  String get paused => 'Paused';

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

  @override
  String errNameNotResolvedDescription(String host) {
    return '$host took too long to respond or could not be resolved.';
  }

  @override
  String errConnectionRefusedDescription(String host) {
    return '$host refused to connect.';
  }

  @override
  String errConnectionTimedOutDescription(String host) {
    return '$host took too long to respond.';
  }

  @override
  String get errInternetDisconnectedDescription => 'Your computer is offline.';

  @override
  String errConnectionResetDescription(String host) {
    return 'The connection to $host was reset.';
  }

  @override
  String errUnreachableDescription(String host) {
    return '$host is unreachable.';
  }

  @override
  String errDefaultDescription(String url) {
    return 'The webpage at $url might be temporarily down or it may have moved permanently to a new web address.';
  }

  @override
  String get errorTryHeader => 'Try:';

  @override
  String get checkNetworkConnection => 'Checking the network connection';

  @override
  String get checkUrlSpelling => 'Checking the URL or domain spelling';

  @override
  String get checkFirewallSettings => 'Checking firewall or proxy settings';

  @override
  String get retry => 'Retry';

  @override
  String get errNameNotResolvedCode => 'ERR_NAME_NOT_RESOLVED';

  @override
  String get errConnectionRefusedCode => 'ERR_CONNECTION_REFUSED';

  @override
  String get errConnectionTimedOutCode => 'ERR_CONNECTION_TIMED_OUT';

  @override
  String get errInternetDisconnectedCode => 'ERR_INTERNET_DISCONNECTED';

  @override
  String get errConnectionResetCode => 'ERR_CONNECTION_RESET';

  @override
  String get errConnectionClosedCode => 'ERR_CONNECTION_CLOSED';

  @override
  String get errAddressUnreachableCode => 'ERR_ADDRESS_UNREACHABLE';

  @override
  String get errCertCommonNameInvalidCode => 'ERR_CERT_COMMON_NAME_INVALID';

  @override
  String get errCertDateInvalidCode => 'ERR_CERT_DATE_INVALID';

  @override
  String get errCertAuthorityInvalidCode => 'ERR_CERT_AUTHORITY_INVALID';

  @override
  String get errInvalidUrlCode => 'ERR_INVALID_URL';

  @override
  String get errUnknownUrlSchemeCode => 'ERR_UNKNOWN_URL_SCHEME';

  @override
  String get errTooManyRedirectsCode => 'ERR_TOO_MANY_REDIRECTS';

  @override
  String errFailedCode(int errorCode) {
    return 'ERR_FAILED ($errorCode)';
  }

  @override
  String get downloadInitError => 'Failed to initialize download history';

  @override
  String get downloadStartError => 'Failed to start download';

  @override
  String get downloadCancelError => 'Failed to cancel download';

  @override
  String get downloadPauseError => 'Failed to pause download';

  @override
  String get downloadResumeError => 'Failed to resume download';

  @override
  String get downloadRemoveError => 'Failed to remove download';

  @override
  String get downloadRetryError => 'Failed to retry download';

  @override
  String get downloadRestartError => 'Failed to restart download';

  @override
  String get downloadClearError => 'Failed to clear completed downloads';

  @override
  String downloadProgressOf(String received, String total) {
    return '$received of $total';
  }
}
