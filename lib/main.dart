import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/services/objectbox_service.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/history/history_bloc.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';
import 'package:show_fps/show_fps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ObjectBoxService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HistoryRepository>(
          create: (context) => HistoryRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DownloadBloc>(create: (context) => DownloadBloc()),
          BlocProvider<BrowserBloc>(
            create: (context) =>
                BrowserBloc(downloadBloc: context.read<DownloadBloc>()),
          ),
          BlocProvider<HistoryBloc>(
            create: (context) =>
                HistoryBloc(repository: context.read<HistoryRepository>()),
          ),
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.dark,
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: showFps
              ? (context, child) {
                  return ShowFPS(
                    visible: showFps,
                    showChart: false,
                    child: child!,
                  );
                }
              : null,
        ),
      ),
    );
  }
}
