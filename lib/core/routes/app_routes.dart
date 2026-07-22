import 'package:flutter/material.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/bookmarks_screen.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/browser_screen.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/downloads_screen.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/history_screen.dart';
import 'package:mechanix_browser/features/browser/presentation/screen/settings_screen.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class AppRoutes {
  static const String home = '/';
  static const String history = '/history';
  static const String bookmarks = '/bookmarks';
  static const String downloads = '/downloads';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const BrowserScreen());
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case bookmarks:
        return MaterialPageRoute(builder: (_) => const BookmarksScreen());
      case downloads:
        return MaterialPageRoute(builder: (_) => const DownloadsScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.noRouteDefined(routeSettings.name ?? ''),
              ),
            ),
          ),
        );
    }
  }
}
