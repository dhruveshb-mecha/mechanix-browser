import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

class DashedShortcutButton extends StatelessWidget {
  final VoidCallback onTap;
  const DashedShortcutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Container(
      height: 82,
      width: 78,
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 26),
      child: OutlinedButton(
        onPressed: onTap,
        style:
            OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              minimumSize: const Size(56, 56),
              maximumSize: const Size(56, 56),
              side: BorderSide(color: colors.shortcutBorder, width: 1.5),
              backgroundColor: Colors.transparent,
              foregroundColor: colors.shortcutForeground,
            ).copyWith(
              side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return BorderSide(
                    color: colors.shortcutHoverBorder,
                    width: 1.5,
                  );
                }
                return BorderSide(color: colors.shortcutBorder, width: 1.5);
              }),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return colors.shortcutHoverBackground;
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return colors.shortcutHoverForeground;
                }
                return colors.shortcutForeground;
              }),
            ),
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }
}
