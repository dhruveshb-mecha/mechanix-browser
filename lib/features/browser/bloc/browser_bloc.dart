import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/core/utils/helpers.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/bookmark_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
// import 'package:mechanix_browser/features/browser/download/bloc/download_bloc.dart';
// import 'package:mechanix_browser/features/browser/download/bloc/download_event.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';
import 'package:mechanix_browser/features/browser/data/repositories/tab_repository.dart';
import 'package:webview_cef/webview_cef.dart';

part 'browser_event.dart';
part 'browser_state.dart';

class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  // final DownloadBloc? downloadBloc;
  final DownloadBloc? downloadBloc;

  /// Repository managing local browser history persistency.
  HistoryRepository? _historyRepository;

  /// Repository managing local bookmarks persistency.
  BookmarkRepository? _bookmarkRepository;

  /// Repository managing local tabs persistency.
  TabRepository? _tabRepository;

  /// Local incremental counter for unique tab ID generation.
  int _tabIdCounter = 0;

  /// Gets the [WebViewController] associated with the active tab.
  WebViewController get controller {
    final tab = state.activeTab;
    if (tab != null) return tab.controller;
    throw StateError("No active tab controller available.");
  }

  /// Initializes a new instance of [BrowserBloc] and registers the event handlers.
  BrowserBloc({this.downloadBloc}) : super(BrowserState.initial()) {
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
    on<BrowserLoadStarted>(_onLoadStarted);
    on<BrowserLoadEnded>(_onLoadEnded);
    on<BrowserBookmarkAdded>(_onBookmarkAdded);
    on<BrowserBookmarkRemoved>(_onBookmarkRemoved);
    on<BrowserBookmarkToggled>(_onBookmarkToggled);
    on<BrowserDevToolsRequested>(_onDevTools);
    on<BrowserHistoryClearRequested>(_onHistoryClearRequested);
  }

  /// Creates a new tab instance with the specified [initialUrl].
  /// Sets up Javascript inject user scripts, instantiates a new CEF webview controller,
  /// attaches event listeners, and initializes the loading of the URL.
  BrowserTab _createNewTab(
    String initialUrl, {
    bool isPrivate = false,
    String? id,
    bool load = true,
  }) {
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
        id ?? 'tab_${DateTime.now().millisecondsSinceEpoch}_${_tabIdCounter++}';
    final listener = _createEventListenerForTab(tabId, controller);
    controller.setWebviewListener(listener);
    if (load) {
      controller.initialize(initialUrl, isPrivate: isPrivate);
    }

    return BrowserTab(
      id: tabId,
      controller: controller,
      currentUrl: initialUrl == AppConstants.homepageUrl ? '' : initialUrl,
      title: '',
      isHomePage: initialUrl == AppConstants.homepageUrl,
      isLoading: false,
      isPrivate: isPrivate,
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
              AppLogger.i(message.message);
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
            .then((value) => AppLogger.i(value));
      },
      onLoadStart: (c, url) {
        AppLogger.i("onLoadStart => $url");
        add(BrowserLoadStarted(tabId: tabId));
      },
      onLoadEnd: (c, url) {
        AppLogger.i("onLoadEnd => $url");
        add(BrowserLoadEnded(tabId: tabId));
      },
      onBeforeDownload:
          (
            c,
            downloadId,
            url,
            suggestedName,
            contentDisposition,
            mimeType,
            totalBytes,
          ) {
            downloadBloc?.add(
              DownloadBeforeStarted(
                controller: c,
                downloadId: downloadId,
                url: url,
                suggestedName: suggestedName,
                contentDisposition: contentDisposition,
                mimeType: mimeType,
                totalBytes: totalBytes,
              ),
            );
          },
      onDownloadUpdated:
          (
            c,
            downloadId,
            url,
            fullPath,
            receivedBytes,
            totalBytes,
            currentSpeed,
            percentComplete,
            isInProgress,
            isComplete,
            isCanceled,
            isInterrupted,
            interruptReason,
          ) {
            downloadBloc?.add(
              DownloadUpdatedEvent(
                controller: c,
                downloadId: downloadId,
                url: url,
                fullPath: fullPath,
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
                currentSpeed: currentSpeed,
                percentComplete: percentComplete,
                isInProgress: isInProgress,
                isComplete: isComplete,
                isCanceled: isCanceled,
                isInterrupted: isInterrupted,
                interruptReason: interruptReason,
              ),
            );
          },
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
      _historyRepository = HistoryRepositoryImpl();
      _bookmarkRepository = BookmarkRepository();
      _tabRepository = await TabRepository.create(
        store: _historyRepository!.store,
      );

      await WebviewManager().initialize(
        userAgent: AppConstants.defaultUserAgent,
      );

      final savedTabs = _tabRepository!.getAllTabs();
      final List<BrowserTab> tabs = [];
      int activeTabIndex = 0;

      if (savedTabs.isEmpty) {
        tabs.add(_createNewTab(AppConstants.homepageUrl));
        activeTabIndex = 0;
      } else {
        for (int i = 0; i < savedTabs.length; i++) {
          final tabEntity = savedTabs[i];
          final tab = _createNewTab(
            tabEntity.url.isEmpty ? AppConstants.homepageUrl : tabEntity.url,
            id: tabEntity.tabId,
            load: tabEntity.isActive,
          );
          tabs.add(tab);
          if (tabEntity.isActive) {
            activeTabIndex = i;
          }
        }
      }

      final favorites = _bookmarkRepository!.getFavorites();
      final bookmarks = _bookmarkRepository!.getBookmarks();
      final history = _historyRepository!.getHistory();

      emit(
        state.copyWith(
          isInitialized: true,
          tabs: tabs,
          activeTabIndex: activeTabIndex,
          favorites: favorites,
          bookmarks: bookmarks,
          searchResults: history,
          isCurrentUrlBookmarked: false,
        ),
      );
    } catch (e) {
      AppLogger.i("Webview initialization error: $e");
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
    try {
      if (!state.isInitialized) return;

      final oldTab = state.activeTab;
      if (oldTab != null) {
        if (oldTab.controller.value) {
          await oldTab.controller.setClientFocus(false);
          await oldTab.controller.wasHidden(true);
          await oldTab.controller.executeJavaScript(
            "document.dispatchEvent(new Event('visibilitychange'))",
          );
        }
      }

      final newTab = _createNewTab(
        event.initialUrl ?? AppConstants.homepageUrl,
        isPrivate: event.isPrivate,
      );
      final updatedTabs = List<BrowserTab>.from(state.tabs)..add(newTab);
      final newActiveIndex = updatedTabs.length - 1;

      emit(state.copyWith(tabs: updatedTabs, activeTabIndex: newActiveIndex));

      _updateCurrentPageBookmarkStatus(emit, targetUrl: newTab.currentUrl);
      _persistTabs();

      newTab.controller.ready.then((_) async {
        final currentActiveTab = state.activeTab;
        if (currentActiveTab != null && currentActiveTab.id == newTab.id) {
          await newTab.controller.setClientFocus(true);
          await newTab.controller.wasHidden(false);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.e("Error opening new tab", error: e, stack: stackTrace);
    }
  }

  /// Handler to close a specific browser tab specified by index.
  Future<void> _onCloseTab(
    BrowserCloseTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
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
      _persistTabs();

      /// focus new tab when new tab ready
      if (newActiveTab.controller.value) {
        await newActiveTab.controller.setClientFocus(true);
      } else {
        newActiveTab.controller.ready.then((_) async {
          final currentActiveTab = state.activeTab;
          if (currentActiveTab != null &&
              currentActiveTab.id == newActiveTab.id) {
            await newActiveTab.controller.setClientFocus(true);
            await newActiveTab.controller.wasHidden(false);
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error closing tab", error: e, stack: stackTrace);
    }
  }

  /// Handler to switch the current view/focus to another tab at the specified index.
  Future<void> _onSwitchTab(
    BrowserSwitchTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final index = event.index;
      if (index < 0 || index >= state.tabs.length) return;
      if (state.activeTabIndex == index) return;

      final oldTab = state.activeTab;
      final newTab = state.tabs[index];

      if (oldTab != null) {
        if (oldTab.controller.value) {
          /// old tab loose focus
          await oldTab.controller.setClientFocus(false);
          await oldTab.controller.wasHidden(true);
          await oldTab.controller.executeJavaScript(
            "document.dispatchEvent(new Event('visibilitychange'))",
          );
        }
      }

      emit(state.copyWith(activeTabIndex: index));
      _updateCurrentPageBookmarkStatus(emit, targetUrl: newTab.currentUrl);
      // _persistTabs();

      /// new tab get focus
      if (newTab.controller.value) {
        await newTab.controller.setClientFocus(true);
        await newTab.controller.wasHidden(false);
      } else {
        newTab.controller.initialize(
          newTab.isHomePage ? AppConstants.homepageUrl : newTab.currentUrl,
          isPrivate: newTab.isPrivate,
        );
        newTab.controller.ready.then((_) async {
          final currentActiveTab = state.activeTab;
          if (currentActiveTab != null && currentActiveTab.id == newTab.id) {
            await newTab.controller.setClientFocus(true);
            await newTab.controller.wasHidden(false);
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error switching tab", error: e, stack: stackTrace);
    }
  }

  /// Handler to dispose of all existing tabs and replace them with a single clean home tab.
  Future<void> _onCloseAllTabs(
    BrowserCloseAllTabsRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      print("Closing all tabs and resetting to homepage.");
      for (final tab in state.tabs) {
        await tab.controller.dispose();
      }

      final firstTab = _createNewTab(AppConstants.homepageUrl);

      emit(state.copyWith(tabs: [firstTab], activeTabIndex: 0));
      _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
      // _persistTabs();

      firstTab.controller.ready.then((_) async {
        final currentActiveTab = state.activeTab;
        if (currentActiveTab != null && currentActiveTab.id == firstTab.id) {
          await firstTab.controller.setClientFocus(true);
          await firstTab.controller.wasHidden(false);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.e("Error closing tabs", error: e, stack: stackTrace);
    }
  }

  /// Helper to persist current tabs state.
  void _persistTabs() {
    if (_tabRepository == null) return;

    final tabsToSave = <TabEntity>[];
    for (int i = 0; i < state.tabs.length; i++) {
      final tab = state.tabs[i];
      tabsToSave.add(
        TabEntity(
          tabId: tab.id,
          tabIndex: i,
          url: tab.isHomePage ? '' : tab.currentUrl,
          title: tab.title,
          isActive: i == state.activeTabIndex,
        ),
      );
    }
    _tabRepository!.deleteAllTabs();
    _tabRepository!.saveAllTabs(tabsToSave);
  }

  /// Handler to load a new URL in the active tab.
  /// Parses the input string as a URL or executes a search engine query if not a valid URL.
  Future<void> _onUrlLoadRequested(
    BrowserUrlLoadRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
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
      // _persistTabs();

      if (activeTab.controller.value) {
        await activeTab.controller.loadUrl(finalUrl);
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error loading URL", error: e, stack: stackTrace);
    }
  }

  Future<void> _onGoBack(
    BrowserGoBackRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final activeTab = state.activeTab;
      if (activeTab != null && activeTab.controller.value) {
        await activeTab.controller.goBack();
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error going back", error: e, stack: stackTrace);
    }
  }

  Future<void> _onGoForward(
    BrowserGoForwardRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final activeTab = state.activeTab;
      if (activeTab != null && activeTab.controller.value) {
        await activeTab.controller.goForward();
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error going forward", error: e, stack: stackTrace);
    }
  }

  Future<void> _onReload(
    BrowserReloadRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final activeTab = state.activeTab;
      if (activeTab != null && activeTab.controller.value) {
        await activeTab.controller.reload();
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error reloading tab", error: e, stack: stackTrace);
    }
  }

  Future<void> _onDevTools(
    BrowserDevToolsRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final activeTab = state.activeTab;
      if (activeTab != null && activeTab.controller.value) {
        await activeTab.controller.openDevTools();
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error opening dev tools", error: e, stack: stackTrace);
    }
  }

  Future<void> _onGoHome(
    BrowserGoHomeRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
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
    } catch (e, stackTrace) {
      AppLogger.e("Error navigating home", error: e, stack: stackTrace);
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
    // _persistTabs();

    // Save URL changes to browser history
    if (_historyRepository != null && !isHome) {
      final parsedUri = Uri.tryParse(event.url.trim());
      if (parsedUri == null || !parsedUri.isAbsolute) {
        AppLogger.i(
          'Skipping history save for invalid/incorrect URL: ${event.url}',
        );
        return;
      }
      try {
        final history = _historyRepository!.getHistory();
        final now = DateTime.now().millisecondsSinceEpoch;
        BrowserHistory? entryToSave;

        if (history.isNotEmpty) {
          final latest = history.first;
          final elapsed = now - latest.timestamp;
          if (elapsed < 1500) {
            AppLogger.i(
              'Redirect/rapid navigation detected (elapsed: ${elapsed}ms). Overwriting latest history entry from ${latest.url} to ${event.url}',
            );
            latest.url = event.url;
            latest.timestamp = now;
            entryToSave = latest;
          }
        }

        if (entryToSave == null) {
          AppLogger.i(
            'Preparing to save new history entry for URL: ${event.url}',
          );
          entryToSave = BrowserHistory(
            url: event.url,
            title: '',
            timestamp: now,
          );
        }

        AppLogger.i(
          'Saving history entry to database: url=${entryToSave.url}, title=${entryToSave.title}',
        );
        _historyRepository!.saveHistory(entryToSave);
        AppLogger.i(
          'Successfully saved history entry: url=${entryToSave.url}, title=${entryToSave.title}',
        );
      } catch (e, stackTrace) {
        AppLogger.e('Error saving history URL', error: e, stack: stackTrace);
      }
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

    // Update the corresponding history entry's title if history is enabled and title is non-empty
    if (_historyRepository != null && event.title.isNotEmpty) {
      try {
        final history = _historyRepository!.getHistory();
        if (history.isNotEmpty) {
          final latest = history.first;
          // Normalize URLs to remove trailing slashes for precise comparison
          final latestUrlNorm = normalizeUrl(latest.url);
          final tabUrlNorm = normalizeUrl(updatedTab.currentUrl);

          // Update the history title if the latest entry's URL matches the current tab URL
          if (latestUrlNorm.toLowerCase() == tabUrlNorm.toLowerCase()) {
            latest.title = event.title;
            AppLogger.i(
              'Preparing to update title for history entry: url=${latest.url}, new title=${latest.title}',
            );
            _historyRepository!.saveHistory(latest);
            AppLogger.i(
              'Successfully updated title for history entry: url=${latest.url}, title=${latest.title}',
            );

            final updatedHistory = _historyRepository!.getHistory();
            emit(state.copyWith(searchResults: updatedHistory));
          }
        }
      } catch (e, stackTrace) {
        AppLogger.e(
          'Error updating history title',
          error: e,
          stack: stackTrace,
        );
      }
    }
  }

  void _onLoadStarted(BrowserLoadStarted event, Emitter<BrowserState> emit) {
    final index = state.tabs.indexWhere((t) => t.id == event.tabId);
    if (index == -1) return;

    final updatedTab = state.tabs[index].copyWith(isLoading: true);

    final updatedTabs = List<BrowserTab>.from(state.tabs);
    updatedTabs[index] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));
  }

  void _onLoadEnded(BrowserLoadEnded event, Emitter<BrowserState> emit) {
    final index = state.tabs.indexWhere((t) => t.id == event.tabId);
    if (index == -1) return;

    final updatedTab = state.tabs[index].copyWith(isLoading: false);

    final updatedTabs = List<BrowserTab>.from(state.tabs);
    updatedTabs[index] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));

    _persistTabs();
  }

  /// Handler to clear all browser history entries from persistent storage.
  Future<void> _onHistoryClearRequested(
    BrowserHistoryClearRequested event,
    Emitter<BrowserState> emit,
  ) async {
    if (_historyRepository != null) {
      _historyRepository!.clearHistory();
      emit(state.copyWith(searchResults: const []));
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
