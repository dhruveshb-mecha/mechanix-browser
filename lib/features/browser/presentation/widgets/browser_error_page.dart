import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_error_info.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BrowserErrorPage extends StatelessWidget {
  final BrowserTab tab;
  final BrowserErrorInfo errorInfo;
  final BrowserBloc bloc;

  const BrowserErrorPage({
    super.key,
    required this.tab,
    required this.errorInfo,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        bloc.add(const BrowserBottomBarVisibilityChanged(true));
      },
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.panelBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.panelBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 36,
                        color: colors.accentActive,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error Title
                    Text(
                      l10n.siteCantBeReached,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.searchBarText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Error Description
                    Text(
                      errorInfo.readableDescription(l10n),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Suggestions section
                    Text(
                      l10n.errorTryHeader,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.searchBarText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _ErrorBulletPoint(text: l10n.checkNetworkConnection),
                    const SizedBox(height: 6),
                    _ErrorBulletPoint(text: l10n.checkUrlSpelling),
                    const SizedBox(height: 6),
                    _ErrorBulletPoint(text: l10n.checkFirewallSettings),

                    const SizedBox(height: 32),

                    // Error Code
                    Text(
                      errorInfo.cefErrorName(l10n),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Action Buttons (Retry)
                    ElevatedButton.icon(
                      onPressed: () {
                        final urlToReload = errorInfo.failedUrl.isNotEmpty
                            ? errorInfo.failedUrl
                            : tab.currentUrl;
                        if (urlToReload.isNotEmpty) {
                          bloc.add(BrowserUrlLoadRequested(urlToReload));
                        } else {
                          bloc.add(const BrowserReloadRequested());
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentActive,
                        foregroundColor: colors.searchBarBackground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBulletPoint extends StatelessWidget {
  final String text;

  const _ErrorBulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 7, right: 10),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: colors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
