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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: colors.closeButtonBackground,
      hoverColor: colors.shortcutHoverBackground,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: colors.searchBarText, size: 24),
      ),
    );
  }
}
