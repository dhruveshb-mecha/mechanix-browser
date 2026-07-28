import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

class MenuPopupButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const MenuPopupButton({
    super.key,
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return IconButton(
      icon: Icon(icon, size: 20),
      color: iconColor ?? colors.searchBarText,
      onPressed: onTap,
      hoverColor: colors.shortcutHoverBackground,
      highlightColor: colors.closeButtonBackground,
      style: IconButton.styleFrom(
        backgroundColor: colors.popupBottomButtonBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
