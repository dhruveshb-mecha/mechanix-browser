import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

class BrowserShortcutItem extends StatelessWidget {
  final String label;
  final String? iconUrl;
  final Color color;
  final VoidCallback onTap;
  final bool isEditMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;

  const BrowserShortcutItem({
    super.key,
    required this.label,
    this.iconUrl,
    required this.color,
    required this.onTap,
    this.isEditMode = false,
    this.onLongPress,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    final Widget letterChild = Text(
      label[0],
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: colors.searchBarBackground,
        letterSpacing: -0.5,
      ),
    );

    final bool hasIconUrl = iconUrl != null && iconUrl!.trim().isNotEmpty;

    final Widget buttonContent = hasIconUrl
        ? ClipOval(
            child: Image.network(
              iconUrl!,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => letterChild,
            ),
          )
        : letterChild;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (!isEditMode) {
                      onTap();
                    }
                  },
                  style:
                      FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        backgroundColor: color,
                        foregroundColor: colors.searchBarBackground,
                        elevation: 0,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (isEditMode) return Colors.transparent;
                          if (states.contains(WidgetState.hovered)) {
                            return colors.popupBarrierColor.withValues(
                              alpha: 0.08,
                            );
                          }
                          if (states.contains(WidgetState.pressed)) {
                            return colors.popupBarrierColor.withValues(
                              alpha: 0.16,
                            );
                          }
                          return null;
                        }),
                      ),
                  child: buttonContent,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -20,
            right: -8,
            child: IgnorePointer(
              ignoring: !isEditMode,
              child: AnimatedScale(
                scale: isEditMode ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: isEditMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRemove,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE35D5D),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
