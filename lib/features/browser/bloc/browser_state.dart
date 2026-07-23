part of 'browser_bloc.dart';

enum BrowserMode { normal, private }

class BrowserState extends Equatable {
  final bool isInitialized;
  final List<BrowserTab> normalTabs;
  final List<BrowserTab> privateTabs;
  final int activeNormalTabIndex;
  final int activePrivateTabIndex;
  final BrowserMode mode;
  final BrowserMode tabSwitcherMode;
  final List<BrowserHistory> searchResults;
  final List<Bookmark> favorites;
  final List<Bookmark> bookmarks;
  final bool isCurrentUrlBookmarked;

  const BrowserState({
    required this.isInitialized,
    required this.normalTabs,
    required this.privateTabs,
    required this.activeNormalTabIndex,
    required this.activePrivateTabIndex,
    required this.mode,
    required this.tabSwitcherMode,
    required this.searchResults,
    required this.favorites,
    required this.bookmarks,
    required this.isCurrentUrlBookmarked,
  });

  const BrowserState.initial()
      : isInitialized = false,
        normalTabs = const [],
        privateTabs = const [],
        activeNormalTabIndex = 0,
        activePrivateTabIndex = 0,
        mode = BrowserMode.normal,
        tabSwitcherMode = BrowserMode.normal,
        searchResults = const [],
        favorites = const [],
        bookmarks = const [],
        isCurrentUrlBookmarked = false;

  List<BrowserTab> get tabs =>
      mode == BrowserMode.normal ? normalTabs : privateTabs;

  int get activeTabIndex =>
      mode == BrowserMode.normal ? activeNormalTabIndex : activePrivateTabIndex;

  BrowserTab? get activeTab =>
      tabs.isNotEmpty && activeTabIndex >= 0 && activeTabIndex < tabs.length
          ? tabs[activeTabIndex]
          : null;

  bool get isHomePage => activeTab?.isHomePage ?? true;
  String get currentUrl => activeTab?.currentUrl ?? '';
  String get title => activeTab?.title ?? '';

  BrowserState copyWith({
    bool? isInitialized,
    List<BrowserTab>? normalTabs,
    List<BrowserTab>? privateTabs,
    int? activeNormalTabIndex,
    int? activePrivateTabIndex,
    BrowserMode? mode,
    BrowserMode? tabSwitcherMode,
    List<BrowserHistory>? searchResults,
    List<Bookmark>? favorites,
    List<Bookmark>? bookmarks,
    bool? isCurrentUrlBookmarked,
  }) {
    return BrowserState(
      isInitialized: isInitialized ?? this.isInitialized,
      normalTabs: normalTabs ?? this.normalTabs,
      privateTabs: privateTabs ?? this.privateTabs,
      activeNormalTabIndex:
          activeNormalTabIndex ?? this.activeNormalTabIndex,
      activePrivateTabIndex:
          activePrivateTabIndex ?? this.activePrivateTabIndex,
      mode: mode ?? this.mode,
      tabSwitcherMode: tabSwitcherMode ?? this.tabSwitcherMode,
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
        normalTabs,
        privateTabs,
        activeNormalTabIndex,
        activePrivateTabIndex,
        mode,
        tabSwitcherMode,
        searchResults,
        favorites,
        bookmarks,
        isCurrentUrlBookmarked,
      ];
}
