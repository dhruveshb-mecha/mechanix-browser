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
