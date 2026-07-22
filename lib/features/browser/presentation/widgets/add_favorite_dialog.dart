import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/favorites/favorite_form_fields.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

import '../../data/models/bookmark.dart';

class AddFavoriteDialog extends StatefulWidget {
  final BrowserBloc bloc;

  const AddFavoriteDialog({super.key, required this.bloc});

  static Future<void> show(BuildContext context, BrowserBloc bloc) {
    return showDialog(
      context: context,
      builder: (context) => AddFavoriteDialog(bloc: bloc),
    );
  }

  @override
  State<AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

class _AddFavoriteDialogState extends State<AddFavoriteDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final activeTab = widget.bloc.state.activeTab;
    if (activeTab != null &&
        !activeTab.isHomePage &&
        activeTab.currentUrl.isNotEmpty) {
      _urlController.text = activeTab.currentUrl;
      _nameController.text = activeTab.title.isNotEmpty
          ? activeTab.title
          : activeTab.currentUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: colors.panelBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.addFavoriteTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.searchBarText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              FavoriteFormFields(
                nameController: _nameController,
                urlController: _urlController,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.searchBarText,
                      backgroundColor: colors.popupBottomButtonBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final name = _nameController.text.trim();
                        final url = _urlController.text.trim();
                        widget.bloc.add(
                          BrowserBookmarkAdded(
                            url: url,
                            label: name,
                            type: BookmarkType.favorite,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.searchBarBackground,
                      backgroundColor: colors.accentActive,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.save,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
