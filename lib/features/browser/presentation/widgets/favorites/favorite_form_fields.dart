import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class FavoriteFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController urlController;

  const FavoriteFormFields({
    super.key,
    required this.nameController,
    required this.urlController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.nameLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: nameController,
          style: TextStyle(color: colors.searchBarText),
          decoration: InputDecoration(
            hintText: l10n.favoriteNameHint,
            hintStyle: TextStyle(color: colors.searchBarHint),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.panelBorder),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.panelBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accentActive),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.urlLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: urlController,
          style: TextStyle(color: colors.searchBarText),
          decoration: InputDecoration(
            hintText: l10n.urlHint,
            hintStyle: TextStyle(color: colors.searchBarHint),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.panelBorder),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.panelBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accentActive),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.pleaseEnterUrl;
            }
            final val = value.trim();
            if (!val.contains('.') || val.contains(' ')) {
              return l10n.pleaseEnterValidUrl;
            }
            return null;
          },
        ),
      ],
    );
  }
}
