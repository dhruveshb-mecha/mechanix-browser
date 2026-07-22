import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/data/repositories/bookmark_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
// import 'package:mechanix_browser/features/browser/download/bloc/download_bloc.dart';
// import 'package:mechanix_browser/features/browser/download/bloc/download_event.dart';
import 'package:webview_cef/webview_cef.dart';

part 'browser_event.dart';
part 'browser_state.dart';

class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  // final DownloadBloc? downloadBloc;

  /// Repository managing local browser history persistency.
  HistoryRepository? _historyRepository;

  /// Repository managing local bookmarks persistency.
  BookmarkRepository? _bookmarkRepository;

  /// Local incremental counter for unique tab ID generation.
  int _tabIdCounter = 0;

  /// Gets the [WebViewController] associated with the active tab.
  WebViewController get controller {
    final tab = state.activeTab;
    if (tab != null) return tab.controller;
    throw StateError("No active tab controller available.");
  }

  /// Initializes a new instance of [BrowserBloc] and registers the event handlers.
  // BrowserBloc({this.downloadBloc}) : super(BrowserState.initial()) {
  BrowserBloc() : super(BrowserState.initial()) {
    on<BrowserInitialized>(_onInitialized);
    on<BrowserUrlLoadRequested>(_onUrlLoadRequested);
    on<BrowserGoBackRequested>(_onGoBack);
    on<BrowserGoForwardRequested>(_onGoForward);
    on<BrowserReloadRequested>(_onReload);
    on<BrowserGoHomeRequested>(_onGoHome);
    on<BrowserUrlChanged>(_onUrlChanged);
    on<BrowserTitleChanged>(_onTitleChanged);
    on<BrowserSearchQueryChanged>(_onSearchQueryChanged);
    on<BrowserHistoryItemDeleted>(_onHistoryItemDeleted);
    on<BrowserNewTabRequested>(_onNewTabRequested);
    on<BrowserCloseTabRequested>(_onCloseTab);
    on<BrowserSwitchTabRequested>(_onSwitchTab);
    on<BrowserCloseAllTabsRequested>(_onCloseAllTabs);
    on<BrowserBookmarkAdded>(_onBookmarkAdded);
    on<BrowserBookmarkRemoved>(_onBookmarkRemoved);
    on<BrowserBookmarkToggled>(_onBookmarkToggled);
    on<BrowserDevToolsRequested>(_onDevTools);
    on<BrowserHistoryClearRequested>(_onHistoryClearRequested);
  }

  /// Creates a new tab instance with the specified [initialUrl].
  /// Sets up Javascript inject user scripts, instantiates a new CEF webview controller,
  /// attaches event listeners, and initializes the loading of the URL.
  BrowserTab _createNewTab(String initialUrl) {
    final injectUserScripts = InjectUserScripts();
    injectUserScripts.add(
      UserScript(
        "console.log('injectScript_in_LoadStart')",
        ScriptInjectTime.LOAD_START,
      ),
    );
    injectUserScripts.add(
      UserScript(
        "console.log('injectScript_in_LoadEnd')",
        ScriptInjectTime.LOAD_END,
      ),
    );

    final controller = WebviewManager().createWebView(
      loading: const Center(child: CircularProgressIndicator()),
      injectUserScripts: injectUserScripts,
    );

    final tabId =
        'tab_${DateTime.now().millisecondsSinceEpoch}_${_tabIdCounter++}';
    final listener = _createEventListenerForTab(tabId, controller);
    controller.setWebviewListener(listener);
    controller.initialize(initialUrl);

    return BrowserTab(
      id: tabId,
      controller: controller,
      currentUrl: initialUrl == AppConstants.homepageUrl ? '' : initialUrl,
      title: '',
      isHomePage: initialUrl == AppConstants.homepageUrl,
    );
  }

  /// Creates and configures a [WebviewEventsListener] for the specified tab ID.
  /// Sets up javascript communication channels and propagates load states, title, and url events to the bloc.
  WebviewEventsListener _createEventListenerForTab(
    String tabId,
    WebViewController controller,
  ) {
    return WebviewEventsListener(
      onTitleChanged: (t) {
        add(BrowserTitleChanged(tabId: tabId, title: t));
      },
      onUrlChanged: (url) {
        add(BrowserUrlChanged(tabId: tabId, url: url));

        final Set<JavascriptChannel> jsChannels = {
          JavascriptChannel(
            name: 'Print',
            onMessageReceived: (JavascriptMessage message) {
              debugPrint(message.message);
              controller.sendJavaScriptChannelCallBack(
                false,
                "{'code':'200','message':'print succeed!'}",
                message.callbackId,
                message.frameId,
              );
            },
          ),
        };
        controller.setJavaScriptChannels(jsChannels);
        controller.executeJavaScript("function abc(e){return 'abc:'+ e}");
        controller
            .evaluateJavascript("abc('test')")
            .then((value) => debugPrint(value));
      },
      onLoadStart: (c, url) {
        debugPrint("onLoadStart => $url");
      },
      onLoadEnd: (c, url) {
        debugPrint("onLoadEnd => $url");
      },
      // onBeforeDownload:
      //     (
      //       c,
      //       downloadId,
      //       url,
      //       suggestedName,
      //       contentDisposition,
      //       mimeType,
      //       totalBytes,
      //     ) {
      //       downloadBloc?.add(
      //         DownloadBeforeStarted(
      //           controller: c,
      //           downloadId: downloadId,
      //           url: url,
      //           suggestedName: suggestedName,
      //           contentDisposition: contentDisposition,
      //           mimeType: mimeType,
      //           totalBytes: totalBytes,
      //         ),
      //       );
      //     },
      // onDownloadUpdated:
      //     (
      //       c,
      //       downloadId,
      //       url,
      //       fullPath,
      //       receivedBytes,
      //       totalBytes,
      //       currentSpeed,
      //       percentComplete,
      //       isInProgress,
      //       isComplete,
      //       isCanceled,
      //       isInterrupted,
      //       interruptReason,
      //     ) {
      //       downloadBloc?.add(
      //         DownloadUpdatedEvent(
      //           controller: c,
      //           downloadId: downloadId,
      //           url: url,
      //           fullPath: fullPath,
      //           receivedBytes: receivedBytes,
      //           totalBytes: totalBytes,
      //           currentSpeed: currentSpeed,
      //           percentComplete: percentComplete,
      //           isInProgress: isInProgress,
      //           isComplete: isComplete,
      //           isCanceled: isCanceled,
      //           isInterrupted: isInterrupted,
      //           interruptReason: interruptReason,
      //         ),
      //       );
      //     },
    );
  }

  /// Handler for the [BrowserInitialized] event.
  /// Asynchronously initializes database repositories (history, bookmarks)
  /// and the global CEF Webview manager instance, and sets up the first home tab.
  Future<void> _onInitialized(
    BrowserInitialized event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      _historyRepository = await HistoryRepository.create();
      _bookmarkRepository = await BookmarkRepository.create(
        store: _historyRepository!.store,
      );

      await WebviewManager().initialize(
        userAgent: AppConstants.defaultUserAgent,
      );

      final firstTab = _createNewTab(AppConstants.homepageUrl);

      final favorites = _bookmarkRepository!.getFavorites();
      final bookmarks = _bookmarkRepository!.getBookmarks();

      emit(
        state.copyWith(
          isInitialized: true,
          tabs: [firstTab],
          activeTabIndex: 0,
          favorites: favorites,
          bookmarks: bookmarks,
          isCurrentUrlBookmarked: false,
        ),
      );
    } catch (e) {
      debugPrint("Webview initialization error: $e");
    }
  }

  /// Reloads bookmarks and favorites list from repository and updates the current active page bookmark status.
  void _refreshFullBookmarksAndFavorites(Emitter<BrowserState> emit) {
    if (_bookmarkRepository == null) return;

    final favorites = _bookmarkRepository!.getFavorites();
    final bookmarks = _bookmarkRepository!.getBookmarks();
    final isBookmarked =
        state.currentUrl.isNotEmpty &&
        bookmarks.any(
          (b) =>
              b.url.trim().toLowerCase() ==
              state.currentUrl.trim().toLowerCase(),
        );

    emit(
      state.copyWith(
        favorites: favorites,
        bookmarks: bookmarks,
        isCurrentUrlBookmarked: isBookmarked,
      ),
    );
  }

  /// Evaluates and updates the bookmark status indicator of the current page.
  void _updateCurrentPageBookmarkStatus(
    Emitter<BrowserState> emit, {
    String? targetUrl,
  }) {
    final currentUrl = (targetUrl ?? state.currentUrl).trim();
    if (currentUrl.isEmpty) {
      emit(state.copyWith(isCurrentUrlBookmarked: false));
      return;
    }

    final isBookmarked = state.bookmarks.any(
      (b) => b.url.trim().toLowerCase() == currentUrl.toLowerCase(),
    );

    emit(state.copyWith(isCurrentUrlBookmarked: isBookmarked));
  }

  /// Handler to add or update a bookmark entry in the repository.
  Future<void> _onBookmarkAdded(
    BrowserBookmarkAdded event,
    Emitter<BrowserState> emit,
  ) async {
    if (_bookmarkRepository == null) return;

    final bookmark = Bookmark.create(
      url: event.url.trim(),
      title: event.label != null && event.label!.isNotEmpty
          ? event.label!.trim()
          : null,
      iconUrl: event.url,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: event.type,
    );

    _bookmarkRepository!.addOrUpdate(bookmark);
    _refreshFullBookmarksAndFavorites(emit);
  }

  /// Handler to remove a bookmark by its ID from the repository.
  Future<void> _onBookmarkRemoved(
    BrowserBookmarkRemoved event,
    Emitter<BrowserState> emit,
  ) async {
    if (_bookmarkRepository == null) return;

    _bookmarkRepository!.remove(event.id);
    _refreshFullBookmarksAndFavorites(emit);
  }

  /// Handler to toggle the bookmark status of the specified URL.
  Future<void> _onBookmarkToggled(
    BrowserBookmarkToggled event,
    Emitter<BrowserState> emit,
  ) async {
    if (_bookmarkRepository == null) return;

    final url = event.url.trim();
    if (url.isEmpty) return;

    final isAlreadyBookmarked = _bookmarkRepository!.isBookmarked(url);
    if (isAlreadyBookmarked) {
      _bookmarkRepository!.removeByUrlAndType(url, BookmarkType.bookmark);
    } else {
      final bookmark = Bookmark.create(
        url: url,
        title: event.title?.trim().isNotEmpty == true
            ? event.title!.trim()
            : null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: BookmarkType.bookmark,
      );
      _bookmarkRepository!.addOrUpdate(bookmark);
    }

    _refreshFullBookmarksAndFavorites(emit);
  }

  /// Handler to spawn a new browser tab with an optional [initialUrl].
  /// Safely unfocuses the current tab and manages tab list and active index updates.
  Future<void> _onNewTabRequested(
    BrowserNewTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    if (!state.isInitialized) return;

    final oldTab = state.activeTab;
    if (oldTab != null) {
      if (oldTab.controller.value) {
        await oldTab.controller.setClientFocus(false);
        await oldTab.controller.executeJavaScript(
          "document.dispatchEvent(new Event('visibilitychange'))",
        );
      }
    }

    final newTab = _createNewTab(event.initialUrl ?? AppConstants.homepageUrl);
    final updatedTabs = List<BrowserTab>.from(state.tabs)..add(newTab);
    final newActiveIndex = updatedTabs.length - 1;

    emit(state.copyWith(tabs: updatedTabs, activeTabIndex: newActiveIndex));

    _updateCurrentPageBookmarkStatus(emit, targetUrl: newTab.currentUrl);

    newTab.controller.ready.then((_) async {
      final currentActiveTab = state.activeTab;
      if (currentActiveTab != null && currentActiveTab.id == newTab.id) {
        await newTab.controller.setClientFocus(true);
      }
    });
  }

  /// Handler to close a specific browser tab specified by index.
  Future<void> _onCloseTab(
    BrowserCloseTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final index = event.index;
    if (index < 0 || index >= state.tabs.length) return;

    /// If only one tab remains, it resets it to the homepage instead of closing.
    if (state.tabs.length == 1) {
      final activeTab = state.tabs[index];
      final updatedTab = activeTab.copyWith(
        isHomePage: true,
        currentUrl: '',
        title: '',
      );
      emit(state.copyWith(tabs: [updatedTab], activeTabIndex: 0));
      _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
      if (activeTab.controller.value) {
        await activeTab.controller.loadUrl(AppConstants.homepageUrl);
      }
      return;
    }

    /// more than one tab find that tab and dispose it controller
    final tabToClose = state.tabs[index];
    await tabToClose.controller.dispose();

    final updatedTabs = List<BrowserTab>.from(state.tabs)..removeAt(index);

    /// find new active tab
    int newActiveIndex = state.activeTabIndex;
    if (index == state.activeTabIndex) {
      if (newActiveIndex >= updatedTabs.length) {
        newActiveIndex = updatedTabs.length - 1;
      }
    } else if (index < state.activeTabIndex) {
      newActiveIndex = state.activeTabIndex - 1;
    }

    emit(state.copyWith(tabs: updatedTabs, activeTabIndex: newActiveIndex));

    final newActiveTab = updatedTabs[newActiveIndex];
    _updateCurrentPageBookmarkStatus(emit, targetUrl: newActiveTab.currentUrl);

    /// focus new tab when new tab ready
    if (newActiveTab.controller.value) {
      await newActiveTab.controller.setClientFocus(true);
    } else {
      newActiveTab.controller.ready.then((_) async {
        final currentActiveTab = state.activeTab;
        if (currentActiveTab != null &&
            currentActiveTab.id == newActiveTab.id) {
          await newActiveTab.controller.setClientFocus(true);
        }
      });
    }
  }

  /// Handler to switch the current view/focus to another tab at the specified index.
  Future<void> _onSwitchTab(
    BrowserSwitchTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final index = event.index;
    if (index < 0 || index >= state.tabs.length) return;
    if (state.activeTabIndex == index) return;

    final oldTab = state.activeTab;
    final newTab = state.tabs[index];

    if (oldTab != null) {
      if (oldTab.controller.value) {
        /// old tab loose focus
        await oldTab.controller.setClientFocus(false);
        await oldTab.controller.executeJavaScript(
          "document.dispatchEvent(new Event('visibilitychange'))",
        );
      }
    }

    emit(state.copyWith(activeTabIndex: index));
    _updateCurrentPageBookmarkStatus(emit, targetUrl: newTab.currentUrl);

    /// new tab get focus
    if (newTab.controller.value) {
      await newTab.controller.setClientFocus(true);
    } else {
      newTab.controller.ready.then((_) async {
        final currentActiveTab = state.activeTab;
        if (currentActiveTab != null && currentActiveTab.id == newTab.id) {
          await newTab.controller.setClientFocus(true);
        }
      });
    }
  }

  /// Handler to dispose of all existing tabs and replace them with a single clean home tab.
  Future<void> _onCloseAllTabs(
    BrowserCloseAllTabsRequested event,
    Emitter<BrowserState> emit,
  ) async {
    for (final tab in state.tabs) {
      await tab.controller.dispose();
    }

    final firstTab = _createNewTab(AppConstants.homepageUrl);

    emit(state.copyWith(tabs: [firstTab], activeTabIndex: 0));
    _updateCurrentPageBookmarkStatus(emit, targetUrl: '');

    firstTab.controller.ready.then((_) async {
      final currentActiveTab = state.activeTab;
      if (currentActiveTab != null && currentActiveTab.id == firstTab.id) {
        await firstTab.controller.setClientFocus(true);
      }
    });
  }

  /// Handler to load a new URL in the active tab.
  /// Parses the input string as a URL or executes a search engine query if not a valid URL.
  Future<void> _onUrlLoadRequested(
    BrowserUrlLoadRequested event,
    Emitter<BrowserState> emit,
  ) async {
    if (!state.isInitialized || state.activeTab == null) return;

    String finalUrl = event.url.trim();
    if (finalUrl.isEmpty) return;

    final isUri = Uri.tryParse(event.url.trim())?.isAbsolute;

    /// check uri is correct or search
    if (!isUri!) {
      if (finalUrl.contains('.') && !finalUrl.contains(' ')) {
        finalUrl = '${AppConstants.defaultScheme}$finalUrl';
      } else {
        finalUrl =
            '${AppConstants.searchUrlPrefix}${Uri.encodeComponent(finalUrl)}';
      }
    }

    final activeTab = state.activeTab!;
    final updatedTab = activeTab.copyWith(
      isHomePage: false,
      currentUrl: finalUrl,
    );
    final updatedTabs = List<BrowserTab>.from(state.tabs);
    updatedTabs[state.activeTabIndex] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs, searchResults: []));
    _updateCurrentPageBookmarkStatus(emit, targetUrl: finalUrl);

    if (activeTab.controller.value) {
      await activeTab.controller.loadUrl(finalUrl);
    }
  }

  Future<void> _onGoBack(
    BrowserGoBackRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final activeTab = state.activeTab;
    if (activeTab != null && activeTab.controller.value) {
      await activeTab.controller.goBack();
    }
  }

  Future<void> _onGoForward(
    BrowserGoForwardRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final activeTab = state.activeTab;
    if (activeTab != null && activeTab.controller.value) {
      await activeTab.controller.goForward();
    }
  }

  Future<void> _onReload(
    BrowserReloadRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final activeTab = state.activeTab;
    if (activeTab != null && activeTab.controller.value) {
      await activeTab.controller.reload();
    }
  }

  Future<void> _onDevTools(
    BrowserDevToolsRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final activeTab = state.activeTab;
    if (activeTab != null && activeTab.controller.value) {
      await activeTab.controller.openDevTools();
    }
  }

  Future<void> _onGoHome(
    BrowserGoHomeRequested event,
    Emitter<BrowserState> emit,
  ) async {
    final activeTab = state.activeTab;
    if (activeTab != null) {
      final updatedTab = activeTab.copyWith(isHomePage: true, currentUrl: '');
      final updatedTabs = List<BrowserTab>.from(state.tabs);
      updatedTabs[state.activeTabIndex] = updatedTab;
      emit(state.copyWith(tabs: updatedTabs));
      _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
      if (activeTab.controller.value) {
        await activeTab.controller.loadUrl(AppConstants.homepageUrl);
      }
    }
  }

  /// Handler triggered when a tab's URL changes.
  /// Updates the tab's state and checks if the new URL is bookmarked.
  void _onUrlChanged(BrowserUrlChanged event, Emitter<BrowserState> emit) {
    final index = state.tabs.indexWhere((t) => t.id == event.tabId);
    if (index == -1) return;

    final isHome = event.url == AppConstants.homepageUrl || event.url.isEmpty;
    final updatedTab = state.tabs[index].copyWith(
      isHomePage: isHome,
      currentUrl: isHome ? '' : event.url,
    );

    final updatedTabs = List<BrowserTab>.from(state.tabs);
    updatedTabs[index] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));
    if (index == state.activeTabIndex) {
      _updateCurrentPageBookmarkStatus(
        emit,
        targetUrl: isHome ? '' : event.url,
      );
    }
  }

  /// Handler triggered when a tab's document title changes.
  void _onTitleChanged(BrowserTitleChanged event, Emitter<BrowserState> emit) {
    final index = state.tabs.indexWhere((t) => t.id == event.tabId);
    if (index == -1) return;

    final updatedTab = state.tabs[index].copyWith(title: event.title);

    final updatedTabs = List<BrowserTab>.from(state.tabs);
    updatedTabs[index] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));
  }

  /// Handler to clear all browser history entries from persistent storage.
  Future<void> _onHistoryClearRequested(
    BrowserHistoryClearRequested event,
    Emitter<BrowserState> emit,
  ) async {
    if (_historyRepository != null) {
      _historyRepository!.clearHistory();
    }
  }

  /// Handler triggered when the search/URL query changes.
  /// Filters the history entries matching the query and updates search results.
  void _onSearchQueryChanged(
    BrowserSearchQueryChanged event,
    Emitter<BrowserState> emit,
  ) {
    if (_historyRepository == null) return;

    if (event.query.trim().isEmpty) {
      final allHistory = _historyRepository!.getHistory();
      emit(state.copyWith(searchResults: allHistory));
      return;
    }

    final results = _historyRepository!.searchHistory(event.query);

    final seenUrls = <String>{};
    final uniqueResults = <BrowserHistory>[];
    for (final item in results) {
      final normalizedUrl = item.url.trim().toLowerCase();
      if (normalizedUrl.isNotEmpty && seenUrls.add(normalizedUrl)) {
        uniqueResults.add(item);
      }
    }

    emit(state.copyWith(searchResults: uniqueResults));
  }

  /// Handler to delete a specific history item and refresh the search result lists.
  void _onHistoryItemDeleted(
    BrowserHistoryItemDeleted event,
    Emitter<BrowserState> emit,
  ) {
    if (_historyRepository != null) {
      _historyRepository!.historyBox.remove(event.item.id);

      if (event.currentQuery.trim().isEmpty) {
        final allHistory = _historyRepository!.getHistory();
        emit(state.copyWith(searchResults: allHistory));
      } else {
        final results = _historyRepository!.searchHistory(event.currentQuery);

        final seenUrls = <String>{};
        final uniqueResults = <BrowserHistory>[];
        for (final item in results) {
          final normalizedUrl = item.url.trim().toLowerCase();
          if (normalizedUrl.isNotEmpty && seenUrls.add(normalizedUrl)) {
            uniqueResults.add(item);
          }
        }

        emit(state.copyWith(searchResults: uniqueResults));
      }
    }
  }

  /// Clean up and dispose of CEF webviews, repositories, and resources.
  @override
  Future<void> close() async {
    for (final tab in state.tabs) {
      tab.controller.dispose();
    }
    await WebviewManager().quit();
    _historyRepository?.close();
    _bookmarkRepository?.close();
    return super.close();
  }
}
