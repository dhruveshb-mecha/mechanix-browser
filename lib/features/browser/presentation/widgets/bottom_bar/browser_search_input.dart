import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BrowserSearchInput extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const BrowserSearchInput({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return SearchBar(
      focusNode: focusNode,
      controller: controller,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(colors.searchBarBackground),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.searchBarBorder, width: 1),
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
      leading: Icon(Icons.lock_outline, color: colors.inactiveGrey, size: 18),
      hintText: l10n.searchOrEnterAddress,
      hintStyle: WidgetStatePropertyAll(
        theme.textTheme.bodyLarge?.copyWith(color: colors.searchBarHint),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.textTheme.bodyLarge?.copyWith(color: colors.searchBarText),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
