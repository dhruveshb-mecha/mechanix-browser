import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/permission/permission_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/permission/site_permission_labels.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

/// Shows the oldest pending permission request of the active tab above the
/// bottom bar. Requests from background tabs wait until their tab is shown.
class PermissionPromptOverlay extends StatelessWidget {
  const PermissionPromptOverlay({super.key});

  static const double _bottomBarHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final browserState = context.watch<BrowserBloc>().state;
    final pending = context.select<PermissionBloc, PendingPermission?>(
      (bloc) => bloc.state.promptFor(browserState.activeTab?.id),
    );
    if (pending == null) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      left: 16,
      right: 16,
      bottom:
          bottomInset +
          (browserState.isBottomBarVisible ? _bottomBarHeight : 0) +
          12,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _PermissionPromptCard(
            key: ValueKey(pending.request),
            pending: pending,
          ),
        ),
      ),
    );
  }
}

class _PermissionPromptCard extends StatelessWidget {
  final PendingPermission pending;

  const _PermissionPromptCard({super.key, required this.pending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<PermissionBloc>();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: colors.panelBackground,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.panelBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.permissionPromptTitle(pending.displayHost),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.searchBarText,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: l10n.permissionNotNow,
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => bloc.add(PermissionPromptClosed(pending)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final kind in pending.kinds)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(kind.icon, size: 22, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kind.requestLabel(l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.searchBarText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (pending.isPrivate) ...[
              const SizedBox(height: 4),
              Text(
                l10n.permissionPromptPrivateNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () =>
                          bloc.add(PermissionDecided(pending, allow: false)),
                      child: Text(l10n.permissionBlock),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () =>
                          bloc.add(PermissionDecided(pending, allow: true)),
                      child: Text(l10n.permissionAllow),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
