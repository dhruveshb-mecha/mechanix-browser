import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

class MenuPopupListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const MenuPopupListTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      ),
      trailing: trailing,
      dense: true,
      hoverColor: colors.closeButtonBackground.withValues(alpha: 0.4),
      splashColor: colors.closeButtonBackground,
      onTap: onTap,
    );
  }
}
