import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/add_favorite_dialog.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/bookmarks/bookmark_tile.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/bookmarks/current_page_bookmark_card.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<BrowserBloc>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.bookmarks,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<BrowserBloc, BrowserState>(
        builder: (context, state) {
          final activeTab = state.activeTab;
          final hasActivePage =
              activeTab != null &&
              !activeTab.isHomePage &&
              activeTab.currentUrl.isNotEmpty;
          final isCurrentBookmarked = state.isCurrentUrlBookmarked;

          final subtitleText = hasActivePage
              ? (activeTab.title.isNotEmpty
                    ? '${activeTab.title} - ${activeTab.currentUrl}'
                    : activeTab.currentUrl)
              : l10n.openPageFirst;

          final favorites = state.favorites;
          final bookmarks = state.bookmarks;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurrentPageBookmarkCard(
                  hasActivePage: hasActivePage,
                  isCurrentBookmarked: isCurrentBookmarked,
                  subtitleText: subtitleText,
                  onTap: hasActivePage
                      ? () {
                          bloc.add(
                            BrowserBookmarkToggled(
                              url: activeTab.currentUrl,
                              title: activeTab.title,
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 28),

                // FAVORITES Section
                Text(
                  l10n.favoritesSectionHeader,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                if (favorites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.noFavoritesSaved,
                      style: TextStyle(color: colors.searchBarHint),
                    ),
                  )
                else
                  ...favorites.map(
                    (fav) => BookmarkTile(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFF4A90E2),
                      title: (fav.title != null && fav.title!.trim().isNotEmpty)
                          ? fav.title!
                          : fav.url,
                      subtitle: fav.url,
                      onTap: () {
                        bloc.add(BrowserUrlLoadRequested(fav.url));
                        Navigator.pop(context);
                      },
                      onRemove: () {
                        bloc.add(
                          BrowserBookmarkRemoved(
                            id: fav.id,
                            type: BookmarkType.favorite,
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // Add favourite dashed button
                InkWell(
                  onTap: () => AddFavoriteDialog.show(context, bloc),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.shortcutBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: colors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.addFavorite,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // BOOKMARKS Section
                Text(
                  l10n.bookmarksSectionHeader,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                if (bookmarks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.noBookmarksSaved,
                      style: TextStyle(color: colors.searchBarHint),
                    ),
                  )
                else
                  ...bookmarks.map(
                    (bm) => BookmarkTile(
                      icon: Icons.bookmark_outline_rounded,
                      iconColor: colors.textSecondary,
                      title: (bm.title != null && bm.title!.trim().isNotEmpty)
                          ? bm.title!
                          : bm.url,
                      subtitle: bm.url,
                      onTap: () {
                        bloc.add(BrowserUrlLoadRequested(bm.url));
                        Navigator.pop(context);
                      },
                      onRemove: () {
                        bloc.add(
                          BrowserBookmarkRemoved(
                            id: bm.id,
                            type: BookmarkType.bookmark,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
