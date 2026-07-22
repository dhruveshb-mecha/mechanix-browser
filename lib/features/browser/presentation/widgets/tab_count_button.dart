import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

class TabCountButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const TabCountButton({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: colors.searchBarText, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          "$count",
          style: TextStyle(
            color: colors.searchBarText,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
