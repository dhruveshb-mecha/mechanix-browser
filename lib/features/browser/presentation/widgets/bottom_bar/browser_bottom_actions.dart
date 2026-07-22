import 'package:flutter/material.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/bottom_icon_button.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/tab_count_button.dart';

class BrowserBottomActions extends StatelessWidget {
  final int tabCount;
  final VoidCallback onNewTab;
  final VoidCallback onOpenTabs;
  final VoidCallback onOpenMenu;

  const BrowserBottomActions({
    super.key,
    required this.tabCount,
    required this.onNewTab,
    required this.onOpenTabs,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 16),
        BottomIconButton(icon: Icons.add, onTap: onNewTab),
        const SizedBox(width: 16),
        TabCountButton(count: tabCount, onTap: onOpenTabs),
        const SizedBox(width: 16),
        BottomIconButton(icon: Icons.menu, onTap: onOpenMenu),
      ],
    );
  }
}
