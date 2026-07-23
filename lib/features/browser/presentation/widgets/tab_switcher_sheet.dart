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

    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        final isPrivateView = state.tabSwitcherMode == BrowserMode.private;
        final tabList = isPrivateView ? state.privateTabs : state.normalTabs;
        final activeIndex = isPrivateView
            ? state.activePrivateTabIndex
            : state.activeNormalTabIndex;

        final sheetBackgroundColor = colors.popupBottomBackground;

        return Container(
          color: sheetBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
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
                      : GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: tabList.length,
                          itemBuilder: (context, index) {
                            final tab = tabList[index];
                            final isActive = index == activeIndex;

                            return Dismissible(
                              key: ValueKey('dismiss_${tab.id}'),
                              direction: DismissDirection.horizontal,
                              onDismissed: (direction) {
                                bloc.add(BrowserCloseTabRequested(tab.id));
                              },
                              child: TabCardItem(
                                tab: tab,
                                isActive: isActive,
                                onTap: () {
                                  bloc.add(BrowserSwitchTabRequested(tab.id));
                                  Navigator.pop(context);
                                },
                                onClose: () {
                                  bloc.add(BrowserCloseTabRequested(tab.id));
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle normal and private modes
                  IconButton(
                    onPressed: () {
                      bloc.add(const BrowserTabSwitcherModeToggled());
                    },
                    tooltip: isPrivateView
                        ? 'Switch to Normal Tabs'
                        : 'Switch to Private Tabs',
                    style: IconButton.styleFrom(
                      // backgroundColor: isPrivateView
                      //     ? colors.accentActive.withValues(alpha: 0.15)
                      //     : Colors.transparent,
                      // backgroundColor: colors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          // color: isPrivateView
                          //     ? colors.accentActive
                          //     : colors.dragHandle,
                          // color: colors.dragHandle,
                          width: 1.5,
                        ),
                      ),
                    ),
                    icon: Image.asset(
                      AppImages.incognitoImage,
                      width: 20,
                      height: 20,
                      color: colors.textSecondary,
                      // color: isPrivateView
                      //     ? colors.accentActive
                      //     : colors.textSecondary,
                    ),
                  ),
                  // Action Buttons (New Private Tab if private list is empty/active, otherwise Close All)
                  Row(
                    children: [
                      if (isPrivateView) ...[
                        TextButton.icon(
                          onPressed: () {
                            bloc.add(
                              const BrowserNewTabRequested(isPrivate: true),
                            );
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.add,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                          label: Text(
                            'New Private Tab',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: colors.accentActive.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: colors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
