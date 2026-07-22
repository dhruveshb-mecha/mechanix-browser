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
    return Material(
      color: colors.popupBottomButtonBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: colors.closeButtonBackground,
        hoverColor: colors.shortcutHoverBackground,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: iconColor ?? colors.searchBarText, size: 20),
        ),
      ),
    );
  }
}
