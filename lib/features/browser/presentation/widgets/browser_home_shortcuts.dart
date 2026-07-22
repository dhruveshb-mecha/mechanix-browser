import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/add_favorite_dialog.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_shortcut_item.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/dashed_shortcut_button.dart';

class BrowserHomeShortcuts extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onExitEditMode;
  final VoidCallback onEnterEditMode;

  const BrowserHomeShortcuts({
    super.key,
    required this.isEditMode,
    required this.onExitEditMode,
    required this.onEnterEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BrowserBloc>();

    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        final favorites = state.favorites
            .take(AppConstants.maxFavoritesCount)
            .toList();
        final showAddButton = favorites.length < AppConstants.maxFavoritesCount;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              ...List.generate(favorites.length, (index) {
                final fav = favorites[index];
                final label =
                    (fav.title != null && fav.title!.trim().isNotEmpty)
                    ? fav.title!
                    : fav.url;
                final color = Theme.of(
                  context,
                ).extension<AppColorsExtension>()!.textSecondary;

                return BrowserShortcutItem(
                  label: label,
                  iconUrl: fav.iconUrl,
                  color: color,
                  isEditMode: isEditMode,
                  onLongPress: onEnterEditMode,
                  onRemove: () {
                    bloc.add(
                      BrowserBookmarkRemoved(
                        id: fav.id,
                        type: BookmarkType.favorite,
                      ),
                    );
                  },
                  onTap: () => bloc.add(BrowserUrlLoadRequested(fav.url)),
                );
              }),
              if (showAddButton)
                DashedShortcutButton(
                  onTap: isEditMode
                      ? onExitEditMode
                      : () => AddFavoriteDialog.show(context, bloc),
                ),
            ],
          ),
        );
      },
    );
  }
}
