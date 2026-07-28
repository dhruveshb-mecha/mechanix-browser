import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

class BottomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const BottomIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return IconButton(
      icon: Icon(icon, size: 24),
      color: colors.searchBarText,
      onPressed: onTap,
      hoverColor: colors.shortcutHoverBackground,
      highlightColor: colors.closeButtonBackground,
      style: IconButton.styleFrom(
        backgroundColor: theme.scaffoldBackgroundColor,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
