import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/routes/app_routes.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/menu/browser_menu_list_section.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

/// Records events instead of running them.
class RecordingBrowserBloc extends BrowserBloc {
  final events = <BrowserEvent>[];

  @override
  void add(BrowserEvent event) => events.add(event);
}

/// Shows the menu until [BrowserMenuListSection.hideMenu] removes it, as the
/// real popup does. The menu returns a Flexible, hence the Column.
class _MenuHost extends StatefulWidget {
  const _MenuHost();

  @override
  State<_MenuHost> createState() => _MenuHostState();
}

class _MenuHostState extends State<_MenuHost> {
  bool _showMenu = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _showMenu
        ? Column(
            children: [
              BrowserMenuListSection(
                state: context.read<BrowserBloc>().state,
                isDesktopSite: false,
                onToggleDesktopSite: (_) {},
                hideMenu: () => setState(() => _showMenu = false),
              ),
            ],
          )
        : const Text('page'),
  );
}

void main() {
  testWidgets('the webview is shown again after leaving a screen opened '
      'from the menu', (tester) async {
    final bloc = RecordingBrowserBloc();
    // Not closed: close() shuts down CEF, which isn't running.

    await tester.pumpWidget(
      BlocProvider<BrowserBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _MenuHost(),
          routes: {
            AppRoutes.history: (_) => const Scaffold(body: Text('History')),
          },
        ),
      ),
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.byType(BrowserMenuListSection), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    final visibility = [
      for (final e in bloc.events)
        if (e is BrowserWasHiddenRequested) e.isHidden,
    ];
    expect(visibility, [true, false]);
  });
}
