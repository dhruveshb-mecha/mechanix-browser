import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/core/utils/history_date_grouper.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/history/history_list_item.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class HistorySection extends StatelessWidget {
  final HistoryGroup group;
  final ValueChanged<BrowserHistory> onItemTap;
  final ValueChanged<BrowserHistory> onItemDelete;

  const HistorySection({
    super.key,
    required this.group,
    required this.onItemTap,
    required this.onItemDelete,
  });

  String _getLocalizedTitle(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context)!;
    switch (title) {
      case 'Today':
        return l10n.today;
      case 'Yesterday':
        return l10n.yesterday;
      case 'This Week':
        return l10n.thisWeek;
      case 'This Month':
        return l10n.thisMonth;
      default:
        return title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    if (group.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
          child: Text(
            _getLocalizedTitle(context, group.title),
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final item = group.items[index];
            return HistoryListItem(
              item: item,
              onTap: () => onItemTap(item),
              onDelete: () => onItemDelete(item),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
