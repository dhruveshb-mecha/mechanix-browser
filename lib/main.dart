import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import 'package:mechanix_browser/features/browser/data/repositories/download_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository_impl.dart';

void main(List<String> args) async {
  final deepLinkUrl = args.isNotEmpty ? args.first : null;
  print(deepLinkUrl);
  WidgetsFlutterBinding.ensureInitialized();
  await ObjectBoxService.initialize();

  runApp(MyApp(initialUrl: deepLinkUrl));
}

class MyApp extends StatefulWidget {
  final String? initialUrl;
  const MyApp({super.key, this.initialUrl});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final BrowserBloc _browserBloc;
  late final DownloadBloc _downloadBloc;
  late final HistoryBloc _historyBloc;

  @override
  void initState() {
    super.initState();
    _downloadBloc = DownloadBloc(
      repository: DownloadRepositoryImpl(),
    )..add(const DownloadInitializeRequested());

    _browserBloc = BrowserBloc(downloadBloc: _downloadBloc);

    _historyBloc = HistoryBloc(repository: HistoryRepositoryImpl());

    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      print("----------------> initial tab isn't null so forwarding the initial url");
      _browserBloc.add(BrowserNewTabRequested(initialUrl: widget.initialUrl));
    }

    _setupSingletonListener();
  }

  void _setupSingletonListener() {
    const channel = BasicMessageChannel<dynamic>(
        'com.mechanix.browser/singleton', StandardMessageCodec());
    channel.setMessageHandler((dynamic message) async {
      if (message is String && message.isNotEmpty) {
        _browserBloc.add(BrowserNewTabRequested(initialUrl: message));
      }
      return null;
    });
  }

  @override
  void dispose() {
    _browserBloc.close();
    _downloadBloc.close();
    _historyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HistoryRepository>(
          create: (context) => HistoryRepositoryImpl(),
        ),
        RepositoryProvider<DownloadRepository>(
          create: (context) => DownloadRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DownloadBloc>.value(value: _downloadBloc),
          BlocProvider<BrowserBloc>.value(value: _browserBloc),
          BlocProvider<HistoryBloc>.value(value: _historyBloc),
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
