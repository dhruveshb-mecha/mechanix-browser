import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Mechanix Browser'**
  String get appTitle;

  /// Hint text for the search bar
  ///
  /// In en, this message translates to:
  /// **'Search or enter address'**
  String get searchOrEnterAddress;

  /// Menu option to open a new tab
  ///
  /// In en, this message translates to:
  /// **'New tab'**
  String get newTab;

  /// Menu option to open a new private tab
  ///
  /// In en, this message translates to:
  /// **'New Private Tab'**
  String get newPrivateTab;

  /// Title of the application in private mode
  ///
  /// In en, this message translates to:
  /// **'{title} (Private)'**
  String appTitlePrivate(String title);

  /// Title for private browsing empty state
  ///
  /// In en, this message translates to:
  /// **'Private Browsing'**
  String get privateBrowsing;

  /// Description for private browsing empty state
  ///
  /// In en, this message translates to:
  /// **'Pages you view in private tabs won\'t be saved in your history, cookie store, or search history after you close all of your private tabs. Bookmarks and downloads will still be kept.'**
  String get privateBrowsingDescription;

  /// Label for private tabs section
  ///
  /// In en, this message translates to:
  /// **'Private Tabs'**
  String get privateTabs;

  /// Label for normal tabs section
  ///
  /// In en, this message translates to:
  /// **'Normal Tabs'**
  String get normalTabs;

  /// Empty state text for private tabs
  ///
  /// In en, this message translates to:
  /// **'No Private Tabs'**
  String get noPrivateTabs;

  /// Empty state text for normal tabs
  ///
  /// In en, this message translates to:
  /// **'No Tabs'**
  String get noTabs;

  /// Tooltip for switching to normal tabs
  ///
  /// In en, this message translates to:
  /// **'Switch to Normal Tabs'**
  String get switchToNormalTabs;

  /// Tooltip for switching to private tabs
  ///
  /// In en, this message translates to:
  /// **'Switch to Private Tabs'**
  String get switchToPrivateTabs;

  /// History feature name
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Bookmarks feature name
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Downloads feature name
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// Share page option
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Desktop site checkbox option
  ///
  /// In en, this message translates to:
  /// **'Desktop site'**
  String get desktopSite;

  /// Developer tools menu option
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get developerTools;

  /// Settings feature name
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Button text to close all tabs
  ///
  /// In en, this message translates to:
  /// **'Close all'**
  String get closeAll;

  /// Indicates that a feature is coming soon
  ///
  /// In en, this message translates to:
  /// **'{feature} is Coming Soon'**
  String comingSoon(String feature);

  /// Subtitle details for coming soon features
  ///
  /// In en, this message translates to:
  /// **'We\'re working hard to bring this feature to you.'**
  String get workingHard;

  /// Snackbar text when private tab is opened
  ///
  /// In en, this message translates to:
  /// **'Private tab opened'**
  String get privateTabOpened;

  /// Snackbar text when sharing a page
  ///
  /// In en, this message translates to:
  /// **'Sharing page...'**
  String get sharingPage;

  /// Snackbar text when bookmarking a page
  ///
  /// In en, this message translates to:
  /// **'Page bookmarked'**
  String get pageBookmarked;

  /// Snackbar text when removing a bookmark
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// Snackbar text when desktop site layout is enabled
  ///
  /// In en, this message translates to:
  /// **'Desktop site enabled'**
  String get desktopSiteEnabled;

  /// Snackbar text when desktop site layout is disabled
  ///
  /// In en, this message translates to:
  /// **'Desktop site disabled'**
  String get desktopSiteDisabled;

  /// Text displayed when route is not found
  ///
  /// In en, this message translates to:
  /// **'No route defined for {routeName}'**
  String noRouteDefined(String routeName);

  /// Button text to add a favorite
  ///
  /// In en, this message translates to:
  /// **'Add favourite'**
  String get addFavorite;

  /// Title of the add favorite dialog
  ///
  /// In en, this message translates to:
  /// **'Add favorite'**
  String get addFavoriteTitle;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Hint for favorite name field
  ///
  /// In en, this message translates to:
  /// **'Favorite name'**
  String get favoriteNameHint;

  /// Label for URL field
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlLabel;

  /// Hint for URL field
  ///
  /// In en, this message translates to:
  /// **'example.com'**
  String get urlHint;

  /// Validation error when URL is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a URL'**
  String get pleaseEnterUrl;

  /// Validation error when URL is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get pleaseEnterValidUrl;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Subtitle text when no active page is available to bookmark
  ///
  /// In en, this message translates to:
  /// **'Open a page first'**
  String get openPageFirst;

  /// Title when current page is already bookmarked
  ///
  /// In en, this message translates to:
  /// **'Current page bookmarked'**
  String get currentPageBookmarked;

  /// Title when current page can be added to bookmarks
  ///
  /// In en, this message translates to:
  /// **'Add current page'**
  String get addCurrentPage;

  /// Section header for favorites
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get favoritesSectionHeader;

  /// Empty state text when no favorites exist
  ///
  /// In en, this message translates to:
  /// **'No favorites saved'**
  String get noFavoritesSaved;

  /// Section header for bookmarks
  ///
  /// In en, this message translates to:
  /// **'BOOKMARKS'**
  String get bookmarksSectionHeader;

  /// Empty state text when no bookmarks exist
  ///
  /// In en, this message translates to:
  /// **'No bookmarks saved'**
  String get noBookmarksSaved;

  /// Hint text for find in page search bar
  ///
  /// In en, this message translates to:
  /// **'Find in page'**
  String get findInPage;

  /// Tooltip for previous match button
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get previousMatch;

  /// Tooltip for next match button
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get nextMatch;

  /// Title text on web error page
  ///
  /// In en, this message translates to:
  /// **'This site can\'t be reached'**
  String get siteCantBeReached;

  /// Description on web error page
  ///
  /// In en, this message translates to:
  /// **'Check if there is a typo in {url}.'**
  String checkTypoInUrl(String url);

  /// Button label to reload page
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// Tooltip for clearing finished downloads
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get clearFinished;

  /// Tooltip for opening downloads directory
  ///
  /// In en, this message translates to:
  /// **'Open Downloads Folder'**
  String get openDownloadsFolder;

  /// Empty state title for downloads
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// Empty state subtitle for downloads
  ///
  /// In en, this message translates to:
  /// **'Files downloaded from web pages will appear here.'**
  String get noDownloadsDescription;

  /// Tooltip/button to open file folder
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// Dialog title for clearing download records
  ///
  /// In en, this message translates to:
  /// **'Clear Downloads'**
  String get clearDownloadsTitle;

  /// Dialog content explanation for clearing downloads
  ///
  /// In en, this message translates to:
  /// **'Do you want to clear download records from history or also delete downloaded files from disk?'**
  String get clearDownloadsDialogContent;

  /// Button label to clear download history without deleting files
  ///
  /// In en, this message translates to:
  /// **'Clear History Only'**
  String get clearHistoryOnly;

  /// Button label to delete files from disk and history records
  ///
  /// In en, this message translates to:
  /// **'Delete Files & History'**
  String get deleteFilesAndHistory;

  /// Dialog title for removing a single download
  ///
  /// In en, this message translates to:
  /// **'Remove Download'**
  String get removeDownloadTitle;

  /// Dialog content for removing a single download
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove \"{filename}\" from history or delete the downloaded file from disk?'**
  String removeDownloadDialogContent(String filename);

  /// Button label to remove single download from history only
  ///
  /// In en, this message translates to:
  /// **'Remove History Only'**
  String get removeHistoryOnly;

  /// Button label to delete single file from disk and history
  ///
  /// In en, this message translates to:
  /// **'Delete File & History'**
  String get deleteFileAndHistory;

  /// Tooltip for resuming or retrying an interrupted download
  ///
  /// In en, this message translates to:
  /// **'Resume / Retry'**
  String get resumeOrRetry;

  /// Tooltip for removing a download
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Download status text for pending downloads
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Download status text for interrupted downloads
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get interrupted;

  /// Download status text for paused downloads
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// Download status text for failed downloads
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Download status text for cancelled downloads
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Error reason for network error
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// Error reason for server error
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// Error reason for user error
  ///
  /// In en, this message translates to:
  /// **'User error'**
  String get userError;

  /// Error reason for file error
  ///
  /// In en, this message translates to:
  /// **'File failed'**
  String get fileFailed;

  /// Toast text for downloading a file
  ///
  /// In en, this message translates to:
  /// **'Downloading {filename}'**
  String downloadingFile(String filename);

  /// Toast text for downloading multiple files
  ///
  /// In en, this message translates to:
  /// **'Downloading files...'**
  String get downloadingFiles;

  /// Button to clear all history entries
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// Tooltip for delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// History group title for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// History group title for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// History group title for this week
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// History group title for this month
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Error description when host name cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'{host} took too long to respond or could not be resolved.'**
  String errNameNotResolvedDescription(String host);

  /// Error description when connection is refused
  ///
  /// In en, this message translates to:
  /// **'{host} refused to connect.'**
  String errConnectionRefusedDescription(String host);

  /// Error description when connection times out
  ///
  /// In en, this message translates to:
  /// **'{host} took too long to respond.'**
  String errConnectionTimedOutDescription(String host);

  /// Error description when computer is offline
  ///
  /// In en, this message translates to:
  /// **'Your computer is offline.'**
  String get errInternetDisconnectedDescription;

  /// Error description when connection was reset
  ///
  /// In en, this message translates to:
  /// **'The connection to {host} was reset.'**
  String errConnectionResetDescription(String host);

  /// Error description when host is unreachable
  ///
  /// In en, this message translates to:
  /// **'{host} is unreachable.'**
  String errUnreachableDescription(String host);

  /// Default web page error description
  ///
  /// In en, this message translates to:
  /// **'The webpage at {url} might be temporarily down or it may have moved permanently to a new web address.'**
  String errDefaultDescription(String url);

  /// Header text for suggestions on error page
  ///
  /// In en, this message translates to:
  /// **'Try:'**
  String get errorTryHeader;

  /// Suggestion bullet point on error page
  ///
  /// In en, this message translates to:
  /// **'Checking the network connection'**
  String get checkNetworkConnection;

  /// Suggestion bullet point on error page
  ///
  /// In en, this message translates to:
  /// **'Checking the URL or domain spelling'**
  String get checkUrlSpelling;

  /// Suggestion bullet point on error page
  ///
  /// In en, this message translates to:
  /// **'Checking firewall or proxy settings'**
  String get checkFirewallSettings;

  /// Button label to retry loading page
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// CEF error code string for name not resolved
  ///
  /// In en, this message translates to:
  /// **'ERR_NAME_NOT_RESOLVED'**
  String get errNameNotResolvedCode;

  /// CEF error code string for connection refused
  ///
  /// In en, this message translates to:
  /// **'ERR_CONNECTION_REFUSED'**
  String get errConnectionRefusedCode;

  /// CEF error code string for connection timed out
  ///
  /// In en, this message translates to:
  /// **'ERR_CONNECTION_TIMED_OUT'**
  String get errConnectionTimedOutCode;

  /// CEF error code string for internet disconnected
  ///
  /// In en, this message translates to:
  /// **'ERR_INTERNET_DISCONNECTED'**
  String get errInternetDisconnectedCode;

  /// CEF error code string for connection reset
  ///
  /// In en, this message translates to:
  /// **'ERR_CONNECTION_RESET'**
  String get errConnectionResetCode;

  /// CEF error code string for connection closed
  ///
  /// In en, this message translates to:
  /// **'ERR_CONNECTION_CLOSED'**
  String get errConnectionClosedCode;

  /// CEF error code string for address unreachable
  ///
  /// In en, this message translates to:
  /// **'ERR_ADDRESS_UNREACHABLE'**
  String get errAddressUnreachableCode;

  /// CEF error code string for invalid cert common name
  ///
  /// In en, this message translates to:
  /// **'ERR_CERT_COMMON_NAME_INVALID'**
  String get errCertCommonNameInvalidCode;

  /// CEF error code string for invalid cert date
  ///
  /// In en, this message translates to:
  /// **'ERR_CERT_DATE_INVALID'**
  String get errCertDateInvalidCode;

  /// CEF error code string for invalid cert authority
  ///
  /// In en, this message translates to:
  /// **'ERR_CERT_AUTHORITY_INVALID'**
  String get errCertAuthorityInvalidCode;

  /// CEF error code string for invalid URL
  ///
  /// In en, this message translates to:
  /// **'ERR_INVALID_URL'**
  String get errInvalidUrlCode;

  /// CEF error code string for unknown URL scheme
  ///
  /// In en, this message translates to:
  /// **'ERR_UNKNOWN_URL_SCHEME'**
  String get errUnknownUrlSchemeCode;

  /// CEF error code string for too many redirects
  ///
  /// In en, this message translates to:
  /// **'ERR_TOO_MANY_REDIRECTS'**
  String get errTooManyRedirectsCode;

  /// Fallback CEF error code string with code number
  ///
  /// In en, this message translates to:
  /// **'ERR_FAILED ({errorCode})'**
  String errFailedCode(int errorCode);

  /// Error message when download history initialization fails
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize download history'**
  String get downloadInitError;

  /// Error message when download fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start download'**
  String get downloadStartError;

  /// Error message when download cancellation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel download'**
  String get downloadCancelError;

  /// Error message when download pause fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pause download'**
  String get downloadPauseError;

  /// Error message when download resume fails
  ///
  /// In en, this message translates to:
  /// **'Failed to resume download'**
  String get downloadResumeError;

  /// Error message when download removal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove download'**
  String get downloadRemoveError;

  /// Error message when download retry fails
  ///
  /// In en, this message translates to:
  /// **'Failed to retry download'**
  String get downloadRetryError;

  /// Error message when download restart fails
  ///
  /// In en, this message translates to:
  /// **'Failed to restart download'**
  String get downloadRestartError;

  /// Error message when clearing downloads fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear completed downloads'**
  String get downloadClearError;

  /// Progress text showing formatted bytes received out of total size
  ///
  /// In en, this message translates to:
  /// **'{received} of {total}'**
  String downloadProgressOf(String received, String total);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
