import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/core/utils/helpers.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/bookmark.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_error_info.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/bookmark_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';
import 'package:mechanix_browser/features/browser/data/repositories/tab_repository.dart';
import 'package:webview_cef/webview_cef.dart';

part 'browser_event.dart';
part 'browser_state.dart';

class BrowserBloc extends Bloc<BrowserEvent, BrowserState> {
  final DownloadBloc? downloadBloc;

  /// Repository managing local browser history persistency.
  HistoryRepository? _historyRepository;

  /// Repository managing local bookmarks persistency.
  BookmarkRepository? _bookmarkRepository;

  /// Repository managing local tabs persistency.
  TabRepository? _tabRepository;

  /// Local incremental counter for unique tab ID generation.
  int _tabIdCounter = 0;

  Timer? _hideTimer;
  bool _isInteracting = false;

  static const Duration bottomBarAutoHideDuration =
      AppConstants.bottomBarAutoHideDuration;

  void _scheduleAutoHideTimer() {
    _cancelAutoHideTimer();
    if (_isInteracting) return;
    _hideTimer = Timer(bottomBarAutoHideDuration, () {
      add(const BrowserBottomBarVisibilityChanged(false));
    });
  }

  void _cancelAutoHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

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
    on<BrowserModeChanged>(_onBrowserModeChanged);
    on<BrowserTabSwitcherOpened>(_onTabSwitcherOpened);
    on<BrowserTabSwitcherModeToggled>(_onTabSwitcherModeToggled);
    on<BrowserBottomBarVisibilityChanged>(_onBottomBarVisibilityChanged);
    on<BrowserWasHiddenRequested>(_onWasHidden);
    on<BrowserLoadErrorOccurred>(_onLoadErrorOccurred);
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
      loading: const Align(
        alignment: Alignment.topCenter,
        child: CircularProgressIndicator(),
      ),
      injectUserScripts: injectUserScripts,
    );

    final tabId =
        id ?? 'tab_${DateTime.now().millisecondsSinceEpoch}_${_tabIdCounter++}';
    final listener = _createEventListenerForTab(
      tabId,
      controller,
      isPrivate: isPrivate,
    );
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
    WebViewController controller, {
    bool isPrivate = false,
  }) {
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
          JavascriptChannel(
            name: 'ScrollChannel',
            onMessageReceived: (JavascriptMessage message) {
              if (message.message == 'atTop') {
                add(const BrowserBottomBarVisibilityChanged(true));
              }
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
      onLoadError: (c, errorCode, errorText, failedUrl, isMainFrame) {
        add(
          BrowserLoadErrorOccurred(
            tabId: tabId,
            errorCode: errorCode,
            errorText: errorText,
            failedUrl: failedUrl,
            isMainFrame: isMainFrame,
          ),
        );
      },
      onLoadEnd: (c, url) {
        add(BrowserLoadEnded(tabId: tabId));

        c.executeJavaScript('''
          (function() {
            let lastScrollY = window.scrollY;
            let atTop = lastScrollY === 0;

            if (atTop) {
              ScrollChannel('atTop');
            }

            window.addEventListener('scroll', () => {
              const currentScrollY = window.scrollY;
              if (currentScrollY === 0 && !atTop) {
                atTop = true;
                ScrollChannel('atTop');
              } else if (currentScrollY > 0 && atTop) {
                atTop = false;
                ScrollChannel('leftTop');
              }
            });
          })();
        ''');
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
                isPrivate: isPrivate,
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
      final startupTabs = List<BrowserTab>.from(state.normalTabs);
      final List<BrowserTab> tabs = [];

      int activeTabIndex = -1;

      if (savedTabs.isEmpty) {
        tabs.add(_createNewTab(AppConstants.homepageUrl));
        activeTabIndex = 0;
      } else {
        for (final tabEntity in savedTabs) {
          final tab = _createNewTab(
            tabEntity.url.isEmpty ? AppConstants.homepageUrl : tabEntity.url,
            id: tabEntity.tabId,
            load: tabEntity.isActive,
          ).copyWith(screenshot: tabEntity.screenshot);

          tabs.add(tab);
          if (tabEntity.isActive) {
            activeTabIndex = tabs.length - 1;
          }
        }
        if (activeTabIndex < 0) activeTabIndex = 0;
      }

      if (startupTabs.isNotEmpty) {
        tabs.addAll(startupTabs);
        activeTabIndex = tabs.length - 1;
      }

      // Ensure activeTabIndex is valid
      if (activeTabIndex < 0) activeTabIndex = 0;

      final favorites = _bookmarkRepository!.getFavorites();
      final bookmarks = _bookmarkRepository!.getBookmarks();
      final history = _historyRepository!.getHistory();

      emit(
        state.copyWith(
          isInitialized: true,
          normalTabs: tabs,
          activeNormalTabIndex: activeTabIndex,
          privateTabs: const [],
          activePrivateTabIndex: -1,
          mode: BrowserMode.normal,
          tabSwitcherMode: BrowserMode.normal,
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
    try {
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
    } catch (e, stackTrace) {
      AppLogger.e("Error adding bookmark", error: e, stack: stackTrace);
    }
  }

  /// Handler to remove a bookmark by its ID from the repository.
  Future<void> _onBookmarkRemoved(
    BrowserBookmarkRemoved event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      if (_bookmarkRepository == null) return;

      _bookmarkRepository!.remove(event.id);
      _refreshFullBookmarksAndFavorites(emit);
    } catch (e, stackTrace) {
      AppLogger.e("Error removing bookmark", error: e, stack: stackTrace);
    }
  }

  /// Handler to toggle the bookmark status of the specified URL.
  Future<void> _onBookmarkToggled(
    BrowserBookmarkToggled event,
    Emitter<BrowserState> emit,
  ) async {
    try {
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
    } catch (e, stackTrace) {
      AppLogger.e("Error toggling bookmark", error: e, stack: stackTrace);
    }
  }

  /// Handler to spawn a new browser tab with an optional [initialUrl].
  /// Safely unfocuses the current tab and manages tab list and active index updates.
  Future<void> _onNewTabRequested(
    BrowserNewTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      if (!state.isInitialized) {
        await WebviewManager().initialize(
          userAgent: AppConstants.defaultUserAgent,
        );
      }
      print("initial url: ${event.initialUrl}");
      final oldTab = state.activeTab;
      if (oldTab != null) {
        await _captureTabScreenshot(oldTab, emit);
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

      final isPrivate = event.isPrivate;
      final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
      final updatedTabs = List<BrowserTab>.from(tabsList)..add(newTab);
      final newActiveIndex = updatedTabs.length - 1;

      _cancelAutoHideTimer();

      if (isPrivate) {
        emit(
          state.copyWith(
            mode: BrowserMode.private,
            tabSwitcherMode: BrowserMode.private,
            privateTabs: updatedTabs,
            activePrivateTabIndex: newActiveIndex,
            isBottomBarVisible: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            mode: BrowserMode.normal,
            tabSwitcherMode: BrowserMode.normal,
            normalTabs: updatedTabs,
            activeNormalTabIndex: newActiveIndex,
            isBottomBarVisible: true,
          ),
        );
        _persistTabs();
      }

      if (!newTab.isLoading) {
        _scheduleAutoHideTimer();
      }

      _updateCurrentPageBookmarkStatus(emit, targetUrl: newTab.currentUrl);

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

  /// Handler to close a specific browser tab specified by unique tab ID.
  Future<void> _onCloseTab(
    BrowserCloseTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final tabId = event.tabId;
      final isPrivate = state.privateTabs.any((t) => t.id == tabId);
      final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
      final activeIndex = isPrivate
          ? state.activePrivateTabIndex
          : state.activeNormalTabIndex;

      final index = tabsList.indexWhere((t) => t.id == tabId);
      if (index == -1) return;
      final tabToClose = tabsList[index];

      /// If only one tab remains in that list
      if (tabsList.length == 1) {
        final activeTab = tabsList[index];
        if (isPrivate) {
          // For private tabs, closing the last one makes the collection empty and displays the private home splash page.
          unawaited(_disposeOrDeferController(activeTab.controller));
          emit(
            state.copyWith(privateTabs: const [], activePrivateTabIndex: -1),
          );
          if (state.mode == BrowserMode.private) {
            _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
          }
        } else {
          // Normal tabs preserve the single home tab resetting behavior.
          final updatedTab = activeTab.copyWith(
            isHomePage: true,
            currentUrl: '',
            title: '',
          );
          emit(
            state.copyWith(normalTabs: [updatedTab], activeNormalTabIndex: 0),
          );
          if (state.mode == BrowserMode.normal) {
            _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
          }
          _persistTabs();
          if (activeTab.controller.value) {
            await activeTab.controller.loadUrl(AppConstants.homepageUrl);
          }
        }
        return;
      }

      unawaited(_disposeOrDeferController(tabToClose.controller));

      final updatedTabs = List<BrowserTab>.from(tabsList)..removeAt(index);

      /// find new active index
      int newActiveIndex = activeIndex;
      if (index == activeIndex) {
        if (newActiveIndex >= updatedTabs.length) {
          newActiveIndex = updatedTabs.length - 1;
        }
      } else if (index < activeIndex) {
        newActiveIndex = activeIndex - 1;
      }

      if (isPrivate) {
        emit(
          state.copyWith(
            privateTabs: updatedTabs,
            activePrivateTabIndex: newActiveIndex,
          ),
        );
      } else {
        emit(
          state.copyWith(
            normalTabs: updatedTabs,
            activeNormalTabIndex: newActiveIndex,
          ),
        );
        _persistTabs();
      }

      final currentTargetTabs = isPrivate
          ? state.privateTabs
          : state.normalTabs;
      if (newActiveIndex >= 0 && newActiveIndex < currentTargetTabs.length) {
        final newActiveTab = currentTargetTabs[newActiveIndex];
        if (state.mode ==
            (isPrivate ? BrowserMode.private : BrowserMode.normal)) {
          _updateCurrentPageBookmarkStatus(
            emit,
            targetUrl: newActiveTab.currentUrl,
          );
        }

        /// focus new tab when ready
        if (newActiveTab.controller.value) {
          await newActiveTab.controller.setClientFocus(true);
          await newActiveTab.controller.wasHidden(false);
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
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error closing tab", error: e, stack: stackTrace);
    }
  }

  /// Handler to switch the current view/focus to another tab specified by tab ID.
  Future<void> _onSwitchTab(
    BrowserSwitchTabRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final tabId = event.tabId;
      final isPrivate = state.privateTabs.any((t) => t.id == tabId);
      final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
      final activeIndex = isPrivate
          ? state.activePrivateTabIndex
          : state.activeNormalTabIndex;

      final index = tabsList.indexWhere((t) => t.id == tabId);
      if (index == -1) return;

      final targetMode = isPrivate ? BrowserMode.private : BrowserMode.normal;
      final oldTab = state.activeTab;
      final newTab = tabsList[index];

      if (state.mode == targetMode && activeIndex == index) return;

      if (oldTab != null) {
        await _captureTabScreenshot(oldTab, emit);
        if (oldTab.controller.value) {
          await oldTab.controller.setClientFocus(false);
          await oldTab.controller.wasHidden(true);
          await oldTab.controller.executeJavaScript(
            "document.dispatchEvent(new Event('visibilitychange'))",
          );
        }
      }

      _cancelAutoHideTimer();

      if (isPrivate) {
        emit(
          state.copyWith(
            mode: targetMode,
            activePrivateTabIndex: index,
            tabSwitcherMode: targetMode,
            isBottomBarVisible: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            mode: targetMode,
            activeNormalTabIndex: index,
            tabSwitcherMode: targetMode,
            isBottomBarVisible: true,
          ),
        );
      }

      if (!newTab.isLoading) {
        _scheduleAutoHideTimer();
      }

      _updateCurrentPageBookmarkStatus(emit, targetUrl: newTab.currentUrl);

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

  /// Handler to dispose of all existing tabs of the active switcher mode.
  Future<void> _onCloseAllTabs(
    BrowserCloseAllTabsRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final isPrivate = state.tabSwitcherMode == BrowserMode.private;
      final tabsList = isPrivate ? state.privateTabs : state.normalTabs;

      for (final tab in tabsList) {
        try {
          unawaited(_disposeOrDeferController(tab.controller));
        } catch (e, stackTrace) {
          AppLogger.e("Error closing controller", error: e, stack: stackTrace);
        }
      }

      if (isPrivate) {
        emit(state.copyWith(privateTabs: const [], activePrivateTabIndex: -1));
        _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
      } else {
        final firstTab = _createNewTab(AppConstants.homepageUrl);
        emit(state.copyWith(normalTabs: [firstTab], activeNormalTabIndex: 0));
        _updateCurrentPageBookmarkStatus(emit, targetUrl: '');
        _persistTabs();

        firstTab.controller.ready.then((_) async {
          final currentActiveTab = state.activeTab;
          if (currentActiveTab != null && currentActiveTab.id == firstTab.id) {
            await firstTab.controller.setClientFocus(true);
            await firstTab.controller.wasHidden(false);
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e("Error closing tabs", error: e, stack: stackTrace);
    }
  }

  /// Safely disposes of a tab's controller or defers disposal until active downloads finish.
  Future<void> _disposeOrDeferController(WebViewController controller) async {
    if (!controller.value) return;

    final hasActiveDownload =
        downloadBloc?.state.downloads.any(
          (d) =>
              (d.status == DownloadStatus.downloading ||
                  d.status == DownloadStatus.pending) &&
              downloadBloc?.isControllerActive(controller) == true,
        ) ??
        false;

    if (hasActiveDownload) {
      AppLogger.i(
        '[BrowserBloc] Tab closed during active download. Hiding webview (wasHidden=true) and deferring dispose until download finishes.',
      );
      try {
        await controller.setClientFocus(false);
        await controller.wasHidden(true);
      } catch (e) {
        AppLogger.e('Error setting wasHidden on background download tab: $e');
      }
      downloadBloc?.registerPendingDisposeController(controller);
    } else {
      await controller.dispose();
    }
  }

  /// Helper to persist current tabs state.
  void _persistTabs() {
    if (_tabRepository == null) return;

    final tabsToSave = <TabEntity>[];
    for (int i = 0; i < state.normalTabs.length; i++) {
      final tab = state.normalTabs[i];
      tabsToSave.add(
        TabEntity(
          tabId: tab.id,
          tabIndex: i,
          url: tab.isHomePage ? '' : tab.currentUrl,
          title: tab.title,
          isActive: i == state.activeNormalTabIndex,
          screenshot: tab.screenshot,
        ),
      );
    }
    _tabRepository!.deleteAllTabs();
    _tabRepository!.saveAllTabs(tabsToSave);
  }

  Future<void> _captureTabScreenshot(
    BrowserTab? tab,
    Emitter<BrowserState> emit,
  ) async {
    if (tab == null) return;
    if (!tab.controller.value) return;
    if (tab.isHomePage || tab.currentUrl.isEmpty) return;
    if (_tabRepository == null) return;

    try {
      final screenshotBytes = await tab.controller.captureScreenshot();
      if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
        final isPrivate = tab.isPrivate;
        final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
        final index = tabsList.indexWhere((t) => t.id == tab.id);

        if (index != -1) {
          final updatedTab = tab.copyWith(screenshot: screenshotBytes);
          final updatedTabs = List<BrowserTab>.from(tabsList);
          updatedTabs[index] = updatedTab;

          if (isPrivate) {
            emit(state.copyWith(privateTabs: updatedTabs));
          } else {
            emit(state.copyWith(normalTabs: updatedTabs));
            _persistTabs();
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error capturing tab screenshot",
        error: e,
        stack: stackTrace,
      );
    }
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

      final isPrivate = activeTab.isPrivate;
      final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
      final activeIndex = isPrivate
          ? state.activePrivateTabIndex
          : state.activeNormalTabIndex;

      final updatedTabs = List<BrowserTab>.from(tabsList);
      updatedTabs[activeIndex] = updatedTab;

      if (isPrivate) {
        emit(state.copyWith(privateTabs: updatedTabs, searchResults: []));
      } else {
        emit(state.copyWith(normalTabs: updatedTabs, searchResults: []));
        _updateCurrentPageBookmarkStatus(emit, targetUrl: finalUrl);
        _persistTabs();
      }

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

        final isPrivate = activeTab.isPrivate;
        final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
        final activeIndex = isPrivate
            ? state.activePrivateTabIndex
            : state.activeNormalTabIndex;

        final updatedTabs = List<BrowserTab>.from(tabsList);
        updatedTabs[activeIndex] = updatedTab;

        if (isPrivate) {
          emit(
            state.copyWith(privateTabs: updatedTabs, isBottomBarVisible: true),
          );
        } else {
          emit(
            state.copyWith(normalTabs: updatedTabs, isBottomBarVisible: true),
          );
          _persistTabs();
        }

        _scheduleAutoHideTimer();
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
    int index = state.normalTabs.indexWhere((t) => t.id == event.tabId);
    bool isPrivate = false;
    if (index == -1) {
      index = state.privateTabs.indexWhere((t) => t.id == event.tabId);
      isPrivate = true;
    }
    if (index == -1) return;

    final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
    final activeIndex = isPrivate
        ? state.activePrivateTabIndex
        : state.activeNormalTabIndex;

    final isHome = event.url == AppConstants.homepageUrl || event.url.isEmpty;
    final updatedTab = tabsList[index].copyWith(
      isHomePage: isHome,
      currentUrl: isHome ? '' : event.url,
    );

    final updatedTabs = List<BrowserTab>.from(tabsList);
    updatedTabs[index] = updatedTab;

    if (isPrivate) {
      emit(state.copyWith(privateTabs: updatedTabs, isBottomBarVisible: true));
    } else {
      emit(state.copyWith(normalTabs: updatedTabs, isBottomBarVisible: true));
      _persistTabs();
    }

    if (state.mode == (isPrivate ? BrowserMode.private : BrowserMode.normal) &&
        index == activeIndex) {
      _updateCurrentPageBookmarkStatus(
        emit,
        targetUrl: isHome ? '' : event.url,
      );
    }

    // Save URL changes to browser history only if NOT private and not a load error
    if (!isPrivate &&
        _historyRepository != null &&
        !isHome &&
        updatedTab.errorInfo == null) {
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
    int index = state.normalTabs.indexWhere((t) => t.id == event.tabId);
    bool isPrivate = false;
    if (index == -1) {
      index = state.privateTabs.indexWhere((t) => t.id == event.tabId);
      isPrivate = true;
    }
    if (index == -1) return;

    final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
    final updatedTab = tabsList[index].copyWith(title: event.title);

    final updatedTabs = List<BrowserTab>.from(tabsList);
    updatedTabs[index] = updatedTab;

    if (isPrivate) {
      emit(state.copyWith(privateTabs: updatedTabs));
    } else {
      emit(state.copyWith(normalTabs: updatedTabs));
    }

    // Update the corresponding history entry's title only if NOT private
    if (!isPrivate && _historyRepository != null && event.title.isNotEmpty) {
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
    int index = state.normalTabs.indexWhere((t) => t.id == event.tabId);
    bool isPrivate = false;
    if (index == -1) {
      index = state.privateTabs.indexWhere((t) => t.id == event.tabId);
      isPrivate = true;
    }
    if (index == -1) return;

    final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
    // clear error on load start
    final updatedTab = tabsList[index].copyWith(
      isLoading: true,
      clearErrorInfo: true,
    );
    final updatedTabs = List<BrowserTab>.from(tabsList);
    updatedTabs[index] = updatedTab;

    if (state.activeTab?.id == event.tabId) {
      _cancelAutoHideTimer();
    }

    if (isPrivate) {
      emit(state.copyWith(privateTabs: updatedTabs, isBottomBarVisible: true));
    } else {
      emit(state.copyWith(normalTabs: updatedTabs, isBottomBarVisible: true));
    }
  }

  void _onLoadEnded(BrowserLoadEnded event, Emitter<BrowserState> emit) {
    int index = state.normalTabs.indexWhere((t) => t.id == event.tabId);
    bool isPrivate = false;
    if (index == -1) {
      index = state.privateTabs.indexWhere((t) => t.id == event.tabId);
      isPrivate = true;
    }
    if (index == -1) return;

    final tabsList = isPrivate ? state.privateTabs : state.normalTabs;
    final updatedTab = tabsList[index].copyWith(isLoading: false);
    final updatedTabs = List<BrowserTab>.from(tabsList);
    updatedTabs[index] = updatedTab;

    if (isPrivate) {
      emit(state.copyWith(privateTabs: updatedTabs, isBottomBarVisible: true));
    } else {
      emit(state.copyWith(normalTabs: updatedTabs, isBottomBarVisible: true));
      _persistTabs();
    }

    if (state.activeTab?.id == event.tabId) {
      _scheduleAutoHideTimer();
    }
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

  Future<void> _onBrowserModeChanged(
    BrowserModeChanged event,
    Emitter<BrowserState> emit,
  ) async {
    if (state.mode == event.mode) return;

    final oldTab = state.activeTab;
    await _captureTabScreenshot(oldTab, emit);

    emit(state.copyWith(mode: event.mode));

    final newTab = state.activeTab;

    if (oldTab != null && oldTab.controller.value) {
      await oldTab.controller.setClientFocus(false);
      await oldTab.controller.wasHidden(true);
      await oldTab.controller.executeJavaScript(
        "document.dispatchEvent(new Event('visibilitychange'))",
      );
    }

    _updateCurrentPageBookmarkStatus(emit);

    if (newTab != null) {
      if (newTab.controller.value) {
        await newTab.controller.setClientFocus(true);
        await newTab.controller.wasHidden(false);
      } else {
        newTab.controller.ready.then((_) async {
          final currentActiveTab = state.activeTab;
          if (currentActiveTab != null && currentActiveTab.id == newTab.id) {
            await newTab.controller.setClientFocus(true);
            await newTab.controller.wasHidden(false);
          }
        });
      }
    }
  }

  void _onTabSwitcherOpened(
    BrowserTabSwitcherOpened event,
    Emitter<BrowserState> emit,
  ) {
    // _captureTabScreenshot(state.activeTab, emit);
    emit(state.copyWith(tabSwitcherMode: state.mode));
  }

  void _onTabSwitcherModeToggled(
    BrowserTabSwitcherModeToggled event,
    Emitter<BrowserState> emit,
  ) {
    final nextMode = state.tabSwitcherMode == BrowserMode.normal
        ? BrowserMode.private
        : BrowserMode.normal;
    emit(state.copyWith(tabSwitcherMode: nextMode));
  }

  void _onBottomBarVisibilityChanged(
    BrowserBottomBarVisibilityChanged event,
    Emitter<BrowserState> emit,
  ) {
    if (event.isInteracting != null) {
      _isInteracting = event.isInteracting!;
    }
    if (event.isVisible) {
      if (!state.isBottomBarVisible) {
        emit(state.copyWith(isBottomBarVisible: true));
      }
      if (_isInteracting) {
        _cancelAutoHideTimer();
      } else {
        _scheduleAutoHideTimer();
      }
    } else {
      _isInteracting = false;
      _cancelAutoHideTimer();
      if (state.isBottomBarVisible) {
        emit(state.copyWith(isBottomBarVisible: false));
      }
    }
  }

  /// Sets the hidden state and client focus of the active webview tab controller.
  Future<void> _onWasHidden(
    BrowserWasHiddenRequested event,
    Emitter<BrowserState> emit,
  ) async {
    try {
      final activeTab = state.activeTab;
      if (activeTab != null && activeTab.controller.value) {
        await activeTab.controller.wasHidden(event.isHidden);
        await activeTab.controller.setClientFocus(!event.isHidden);
      }
    } catch (e, stackTrace) {
      AppLogger.w("Error setting wasHidden state: $e $stackTrace");
    }
  }

  /// Updates the target tab state with error details for main frame navigation failures.
  void _onLoadErrorOccurred(
    BrowserLoadErrorOccurred event,
    Emitter<BrowserState> emit,
  ) {
    try {
      // Only handle main frame navigation errors and ignore ERR_ABORTED (-3)
      if (!event.isMainFrame || event.errorCode == -3) {
        return;
      }

      // Search for tab index in normal and private tab lists
      int index = state.normalTabs.indexWhere((t) => t.id == event.tabId);
      bool isPrivate = false;
      if (index == -1) {
        index = state.privateTabs.indexWhere((t) => t.id == event.tabId);
        isPrivate = true;
      }
      if (index == -1) return;

      final tabsList = isPrivate ? state.privateTabs : state.normalTabs;

      final errorInfo = BrowserErrorInfo(
        errorCode: event.errorCode,
        errorText: event.errorText,
        failedUrl: event.failedUrl,
      );

      // Update tab with error details and clear loading flag
      final updatedTab = tabsList[index].copyWith(
        errorInfo: errorInfo,
        currentUrl: event.failedUrl,
        isLoading: false,
      );

      final updatedTabs = List<BrowserTab>.from(tabsList);
      updatedTabs[index] = updatedTab;

      if (isPrivate) {
        emit(state.copyWith(privateTabs: updatedTabs));
      } else {
        emit(state.copyWith(normalTabs: updatedTabs));
      }
    } catch (e, stackTrace) {
      AppLogger.w("Error loading URL: $e $stackTrace");
    }
  }

  /// Clean up and dispose of CEF webviews, repositories, and resources.
  @override
  Future<void> close() async {
    _cancelAutoHideTimer();
    for (final tab in state.normalTabs) {
      tab.controller.dispose();
    }
    for (final tab in state.privateTabs) {
      tab.controller.dispose();
    }
    await WebviewManager().quit();
    _historyRepository?.close();
    _bookmarkRepository?.close();
    return super.close();
  }
}
