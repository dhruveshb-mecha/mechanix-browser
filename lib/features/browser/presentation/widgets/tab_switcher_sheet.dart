import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/tab_switcher/tab_card_item.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class TabSwitcherSheet extends StatelessWidget {
  final BrowserBloc bloc;

  const TabSwitcherSheet({super.key, required this.bloc});

  static void show(BuildContext context, BrowserBloc bloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BlocProvider.value(
          value: bloc,
          child: TabSwitcherSheet(bloc: bloc),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: BlocBuilder<BrowserBloc, BrowserState>(
        builder: (context, state) {
          return Column(
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.dragHandle,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              // Tab grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: state.tabs.length,
                  itemBuilder: (context, index) {
                    final tab = state.tabs[index];
                    final isActive = index == state.activeTabIndex;

                    return TabCardItem(
                      tab: tab,
                      isActive: isActive,
                      onTap: () {
                        bloc.add(BrowserSwitchTabRequested(index));
                        Navigator.pop(context);
                      },
                      onClose: () {
                        bloc.add(BrowserCloseTabRequested(index));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      bloc.add(const BrowserCloseAllTabsRequested());
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.searchBarText,
                      backgroundColor: colors.popupBottomButtonBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.closeAll,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
