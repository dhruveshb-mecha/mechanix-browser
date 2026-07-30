import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/tab_switcher/tab_card_item.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class TabSwitcherSheet extends StatelessWidget {
  final BrowserBloc bloc;

  const TabSwitcherSheet({super.key, required this.bloc});

  static void show(BuildContext context, BrowserBloc bloc) {
    bloc.add(const BrowserTabSwitcherOpened());
    bloc.add(const BrowserWasHiddenRequested(true));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return BlocProvider.value(
          value: bloc,
          child: TabSwitcherSheet(bloc: bloc),
        );
      },
    ).then((_) {
      bloc.add(const BrowserWasHiddenRequested(false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final targetHeight = screenHeight - statusBarHeight - 24;

    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        final isPrivateView = state.tabSwitcherMode == BrowserMode.private;
        final tabList = isPrivateView ? state.privateTabs : state.normalTabs;
        final activeIndex = isPrivateView
            ? state.activePrivateTabIndex
            : state.activeNormalTabIndex;

        final sheetBackgroundColor = colors.popupBottomBackground;

        return Container(
          height: targetHeight,
          color: sheetBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
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
              const SizedBox(height: 12),
              // Title indicating section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPrivateView) ...[
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 16,
                      // color: colors.accentActive,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Private Tabs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Normal Tabs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.searchBarText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Tab grid
              Flexible(
                child: tabList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPrivateView
                                    ? Icons.visibility_off_rounded
                                    : Icons.public,
                                size: 48,
                                color: colors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isPrivateView ? 'No Private Tabs' : 'No Tabs',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const crossAxisSpacing = 16.0;
                          const mainAxisSpacing = 16.0;
                          const childAspectRatio = 0.75;
                          const columns = 2;

                          final totalSpacing = crossAxisSpacing * (columns - 1);
                          final itemWidth =
                              (constraints.maxWidth - totalSpacing) / columns;
                          final itemHeight = itemWidth / childAspectRatio;

                          final rowCount = (tabList.length / columns).ceil();
                          final gridHeight =
                              rowCount * itemHeight +
                              (rowCount > 0
                                  ? (rowCount - 1) * mainAxisSpacing
                                  : 0);

                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: SizedBox(
                              height: gridHeight,
                              child: Stack(
                                children: List.generate(tabList.length, (
                                  index,
                                ) {
                                  final tab = tabList[index];
                                  final isActive = index == activeIndex;

                                  final row = index ~/ columns;
                                  final col = index % columns;

                                  final left =
                                      col * (itemWidth + crossAxisSpacing);
                                  final top =
                                      row * (itemHeight + mainAxisSpacing);

                                  return AnimatedPositioned(
                                    key: ValueKey('pos_${tab.id}'),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    left: left,
                                    top: top,
                                    width: itemWidth,
                                    height: itemHeight,
                                    child: Dismissible(
                                      key: ValueKey('dismiss_${tab.id}'),
                                      direction: DismissDirection.horizontal,
                                      onDismissed: (direction) {
                                        bloc.add(
                                          BrowserCloseTabRequested(tab.id),
                                        );
                                      },
                                      child: TabCardItem(
                                        tab: tab,
                                        isActive: isActive,
                                        onTap: () {
                                          bloc.add(
                                            BrowserSwitchTabRequested(tab.id),
                                          );
                                          Navigator.pop(context);
                                        },
                                        onClose: () {
                                          bloc.add(
                                            BrowserCloseTabRequested(tab.id),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle normal and private modes
                  IconButton(
                    onPressed: () {
                      final targetIsPrivate = !isPrivateView;
                      final targetTabs = targetIsPrivate
                          ? state.privateTabs
                          : state.normalTabs;
                      if (targetTabs.isEmpty) {
                        bloc.add(
                          BrowserNewTabRequested(isPrivate: targetIsPrivate),
                        );
                        Navigator.pop(context);
                      } else {
                        bloc.add(const BrowserTabSwitcherModeToggled());
                      }
                    },
                    tooltip: isPrivateView
                        ? 'Switch to Normal Tabs'
                        : 'Switch to Private Tabs',
                    hoverColor: colors.shortcutHoverBackground,
                    highlightColor: colors.closeButtonBackground,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Image.asset(
                      AppImages.incognitoImage,
                      width: 24,
                      height: 24,
                      color: colors.searchBarText,
                    ),
                  ),
                  // Action Buttons (New Private Tab if private list is empty/active, otherwise Close All)
                  Row(
                    children: [
                      if (tabList.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            bloc.add(const BrowserCloseAllTabsRequested());
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.searchBarText,
                            backgroundColor: colors.popupBottomButtonBackground,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
