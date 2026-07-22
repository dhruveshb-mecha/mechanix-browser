part of 'browser_bloc.dart';

class BrowserState extends Equatable {
  final bool isInitialized;
  final List<BrowserTab> tabs;
  final int activeTabIndex;
  final List<BrowserHistory> searchResults;
  final List<Bookmark> favorites;
  final List<Bookmark> bookmarks;
  final bool isCurrentUrlBookmarked;

  const BrowserState({
    required this.isInitialized,
    required this.tabs,
    required this.activeTabIndex,
    required this.searchResults,
    required this.favorites,
    required this.bookmarks,
    required this.isCurrentUrlBookmarked,
  });

  const BrowserState.initial()
      : isInitialized = false,
        tabs = const [],
        activeTabIndex = 0,
        searchResults = const [],
        favorites = const [],
        bookmarks = const [],
        isCurrentUrlBookmarked = false;

  BrowserTab? get activeTab =>
      tabs.isNotEmpty && activeTabIndex >= 0 && activeTabIndex < tabs.length
          ? tabs[activeTabIndex]
          : null;
  bool get isHomePage => activeTab?.isHomePage ?? true;
  String get currentUrl => activeTab?.currentUrl ?? '';
  String get title => activeTab?.title ?? '';

  BrowserState copyWith({
    bool? isInitialized,
    List<BrowserTab>? tabs,
    int? activeTabIndex,
    List<BrowserHistory>? searchResults,
    List<Bookmark>? favorites,
    List<Bookmark>? bookmarks,
    bool? isCurrentUrlBookmarked,
  }) {
    return BrowserState(
      isInitialized: isInitialized ?? this.isInitialized,
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      searchResults: searchResults ?? this.searchResults,
      favorites: favorites ?? this.favorites,
      bookmarks: bookmarks ?? this.bookmarks,
      isCurrentUrlBookmarked:
          isCurrentUrlBookmarked ?? this.isCurrentUrlBookmarked,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        tabs,
        activeTabIndex,
        searchResults,
        favorites,
        bookmarks,
        isCurrentUrlBookmarked,
      ];
}
