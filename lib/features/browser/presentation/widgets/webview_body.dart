import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_tab.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_error_page.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/home_page_body.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/swipe_gesture_classifier.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BrowserWebviewBody extends StatelessWidget {
  const BrowserWebviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowserBloc, BrowserState>(
      buildWhen: (previous, current) =>
          previous.normalTabs != current.normalTabs ||
          previous.privateTabs != current.privateTabs ||
          previous.activeNormalTabIndex != current.activeNormalTabIndex ||
          previous.activePrivateTabIndex != current.activePrivateTabIndex ||
          previous.mode != current.mode,
      builder: (context, state) {
        final isPrivateEmpty =
            state.mode == BrowserMode.private && state.privateTabs.isEmpty;

        if (isPrivateEmpty) {
          return _PrivateEmptyStateView(
            onCreatePrivateTab: () {
              context.read<BrowserBloc>().add(
                const BrowserNewTabRequested(isPrivate: true),
              );
            },
          );
        }

        final allTabs = [...state.normalTabs, ...state.privateTabs];
        if (allTabs.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeTab = state.activeTab;
        final activeIndex = allTabs.indexWhere((t) => t.id == activeTab?.id);

        return IndexedStack(
          index: activeIndex >= 0 ? activeIndex : 0,
          children: allTabs.map((tab) {
            return Stack(
              key: ValueKey('stack_${tab.id}'),
              children: [
                Row(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: tab.controller,
                      builder: (context, value, child) {
                        if (!tab.controller.value) {
                          return Expanded(child: tab.controller.loadingWidget);
                        }
                        if (tab.isHomePage) {
                          return Expanded(child: tab.controller.webviewWidget);
                        }
                        return Expanded(
                          child: BrowserGestureNavigator(
                            tab: tab,
                            bloc: context.read<BrowserBloc>(),
                            child: tab.controller.webviewWidget,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (tab.isHomePage)
                  Positioned.fill(
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: const BrowserHomePageBody(),
                    ),
                  ),
                // error page body
                if (!tab.isHomePage && tab.errorInfo != null)
                  Positioned.fill(
                    child: BrowserGestureNavigator(
                      tab: tab,
                      bloc: context.read<BrowserBloc>(),
                      child: BrowserErrorPage(
                        tab: tab,
                        errorInfo: tab.errorInfo!,
                        bloc: context.read<BrowserBloc>(),
                      ),
                    ),
                  ),
                if (!tab.isHomePage)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BrowserLoadingBar(isLoading: tab.isLoading),
                  ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class _BrowserLoadingBar extends StatefulWidget {
  final bool isLoading;

  const _BrowserLoadingBar({required this.isLoading});

  @override
  State<_BrowserLoadingBar> createState() => _BrowserLoadingBarState();
}

class _BrowserLoadingBarState extends State<_BrowserLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isLoading) {
      _startLoading();
    }
  }

  @override
  void didUpdateWidget(covariant _BrowserLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startLoading();
      } else {
        _completeLoading();
      }
    }
  }

  void _startLoading() {
    setState(() {
      _opacity = 1.0;
    });
    _controller.reset();
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.animateTo(1.0, duration: const Duration(milliseconds: 3000));
  }

  void _completeLoading() {
    final currentVal = _animation.value;
    _animation = Tween<double>(
      begin: currentVal,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.reset();
    _controller
        .animateTo(1.0, duration: const Duration(milliseconds: 300))
        .then((_) {
          if (mounted && !widget.isLoading) {
            setState(() {
              _opacity = 0.0;
            });
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 200),
      child: _opacity == 0.0
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _animation.value,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF30E3CA), Color(0xFF11998E)],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PrivateEmptyStateView extends StatelessWidget {
  final VoidCallback onCreatePrivateTab;

  const _PrivateEmptyStateView({required this.onCreatePrivateTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.accentActive.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.accentActive.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.visibility_off_rounded,
                  color: colors.accentActive,
                  size: 56,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.privateBrowsing,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  l10n.privateBrowsingDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GestureType { undecided, horizontal, vertical }

class BrowserGestureNavigator extends StatefulWidget {
  final BrowserTab tab;
  final BrowserBloc bloc;
  final Widget child;

  const BrowserGestureNavigator({
    super.key,
    required this.tab,
    required this.bloc,
    required this.child,
  });

  @override
  State<BrowserGestureNavigator> createState() =>
      _BrowserGestureNavigatorState();
}

class _BrowserGestureNavigatorState extends State<BrowserGestureNavigator>
    with SingleTickerProviderStateMixin {
  static const double bottomBarScrollThreshold = 40.0;
  static const Duration indicatorDismissDuration = Duration(milliseconds: 200);

  Offset? _startPosition;
  bool _isGestureRejected = false;
  bool _hasNavigated = false;

  double _accumulatedScroll = 0.0;
  bool? _isScrollDirectionDown;
  _GestureType _gestureType = _GestureType.undecided;

  SwipeDirection _indicatorDirection = SwipeDirection.none;
  double _swipeProgress = 0.0;
  bool _isNavigationAvailable = false;

  bool _canGoBack = false;
  bool _canGoForward = false;

  late AnimationController _dismissController;
  Animation<double>? _dismissAnimation;

  @override
  void initState() {
    super.initState();
    _dismissController =
        AnimationController(vsync: this, duration: indicatorDismissDuration)
          ..addListener(() {
            setState(() {
              _swipeProgress = _dismissAnimation?.value ?? 0.0;
            });
          });
    _updateNavigationAvailability();
  }

  @override
  void didUpdateWidget(covariant BrowserGestureNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.id != oldWidget.tab.id ||
        widget.tab.currentUrl != oldWidget.tab.currentUrl) {
      _dismissIndicatorImmediate();
      _updateNavigationAvailability();
    }
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  Future<void> _updateNavigationAvailability() async {
    final canBack = await widget.tab.controller.canGoBack();
    final canForward = await widget.tab.controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    }
  }

  void _dismissIndicatorImmediate() {
    _dismissController.stop();
    if (_swipeProgress != 0.0 || _indicatorDirection != SwipeDirection.none) {
      setState(() {
        _swipeProgress = 0.0;
        _indicatorDirection = SwipeDirection.none;
      });
    }
  }

  void _dismissIndicatorSmoothly() {
    if (_swipeProgress == 0.0) {
      setState(() {
        _indicatorDirection = SwipeDirection.none;
      });
      return;
    }
    _dismissAnimation = Tween<double>(begin: _swipeProgress, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOutCubic),
    );
    _dismissController.forward(from: 0.0).then((_) {
      if (mounted && _dismissController.value == 1.0) {
        setState(() {
          _indicatorDirection = SwipeDirection.none;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (PointerDownEvent event) {
              if (event.kind != PointerDeviceKind.touch) {
                _isGestureRejected = true;
                return;
              }
              _dismissController.stop();
              _startPosition = event.localPosition;
              _isGestureRejected = false;
              _hasNavigated = false;
              _gestureType = _GestureType.undecided;
              _accumulatedScroll = 0.0;
              _indicatorDirection = SwipeDirection.none;
              _swipeProgress = 0.0;
              _updateNavigationAvailability();
            },
            onPointerMove: (PointerMoveEvent event) {
              if (_startPosition == null) return;

              final dx = event.localPosition.dx - _startPosition!.dx;
              final dy = event.localPosition.dy - _startPosition!.dy;

              // 1. Determine gesture type if undecided
              if (_gestureType == _GestureType.undecided) {
                if (dx.abs() > 10 || dy.abs() > 10) {
                  if (dy.abs() > dx.abs()) {
                    _gestureType = _GestureType.vertical;
                    _isGestureRejected =
                        true; // Reject swipe navigation gesture
                  } else {
                    _gestureType = _GestureType.horizontal;
                  }
                }
              }

              // 2. Track vertical scrolling delta
              if (_gestureType == _GestureType.vertical) {
                final deltaY = event.delta.dy;
                if (deltaY.abs() > 0.5) {
                  final currentScrollDown =
                      deltaY < 0; // Finger moves up -> scroll down

                  if (_isScrollDirectionDown != currentScrollDown) {
                    _isScrollDirectionDown = currentScrollDown;
                    _accumulatedScroll = 0.0;
                  }

                  _accumulatedScroll += deltaY.abs();

                  if (_accumulatedScroll >= bottomBarScrollThreshold) {
                    _accumulatedScroll = 0.0;
                    final currentVisible = widget.bloc.state.isBottomBarVisible;
                    if (currentScrollDown && currentVisible) {
                      widget.bloc.add(
                        const BrowserBottomBarVisibilityChanged(false),
                      );
                    } else if (!currentScrollDown && !currentVisible) {
                      widget.bloc.add(
                        const BrowserBottomBarVisibilityChanged(true),
                      );
                    }
                  }
                }
              }

              if (_isGestureRejected || _hasNavigated) {
                return;
              }

              // 3. Track horizontal gesture progress for indicator
              if (_gestureType == _GestureType.horizontal) {
                final isSwipingRight = dx > 0;
                final isSwipingLeft = dx < 0;
                final direction = isSwipingRight
                    ? SwipeDirection.back
                    : (isSwipingLeft
                          ? SwipeDirection.forward
                          : SwipeDirection.none);
                final isAvailable = isSwipingRight
                    ? _canGoBack
                    : (isSwipingLeft ? _canGoForward : false);

                final rawProgress =
                    dx.abs() / SwipeGestureClassifier.navigationSwipeThreshold;
                final progress = isAvailable
                    ? rawProgress.clamp(0.0, 1.2)
                    : rawProgress.clamp(0.0, 0.3);

                setState(() {
                  _indicatorDirection = direction;
                  _isNavigationAvailable = isAvailable;
                  _swipeProgress = progress;
                });
              }
            },
            onPointerSignal: (PointerSignalEvent signal) {
              if (signal is PointerScrollEvent) {
                final deltaY = signal.scrollDelta.dy;
                if (deltaY.abs() > 2.0) {
                  final currentScrollDown = deltaY > 0;

                  if (_isScrollDirectionDown != currentScrollDown) {
                    _isScrollDirectionDown = currentScrollDown;
                    _accumulatedScroll = 0.0;
                  }

                  _accumulatedScroll += deltaY.abs();

                  if (_accumulatedScroll >= bottomBarScrollThreshold) {
                    _accumulatedScroll = 0.0;
                    final currentVisible = widget.bloc.state.isBottomBarVisible;
                    if (currentScrollDown && currentVisible) {
                      widget.bloc.add(
                        const BrowserBottomBarVisibilityChanged(false),
                      );
                    } else if (!currentScrollDown && !currentVisible) {
                      widget.bloc.add(
                        const BrowserBottomBarVisibilityChanged(true),
                      );
                    }
                  }
                }
              }
            },
            onPointerUp: (PointerUpEvent event) async {
              final wasUndecided = _gestureType == _GestureType.undecided;
              _gestureType = _GestureType.undecided;
              _accumulatedScroll = 0.0;

              if (!_isGestureRejected &&
                  !_hasNavigated &&
                  _startPosition != null) {
                final direction = SwipeGestureClassifier.classify(
                  startPosition: _startPosition!,
                  endPosition: event.localPosition,
                );

                if (direction == SwipeDirection.back) {
                  final canGoBack = await widget.tab.controller.canGoBack();
                  if (canGoBack) {
                    _hasNavigated = true;
                    widget.bloc.add(const BrowserGoBackRequested());
                  }
                } else if (direction == SwipeDirection.forward) {
                  final canGoForward = await widget.tab.controller
                      .canGoForward();
                  if (canGoForward) {
                    _hasNavigated = true;
                    widget.bloc.add(const BrowserGoForwardRequested());
                  }
                } else if (direction == SwipeDirection.none && wasUndecided) {
                  widget.bloc.add(
                    const BrowserBottomBarVisibilityChanged(true),
                  );
                }
              }

              _startPosition = null;
              _dismissIndicatorSmoothly();
            },
            onPointerCancel: (PointerCancelEvent event) {
              _gestureType = _GestureType.undecided;
              _accumulatedScroll = 0.0;
              _startPosition = null;
              _dismissIndicatorSmoothly();
            },
            child: widget.child,
          ),
          if (_indicatorDirection != SwipeDirection.none && _swipeProgress > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: _SwipeCaretIndicator(
                  key: const Key('swipe_caret_indicator'),
                  direction: _indicatorDirection,
                  progress: _swipeProgress,
                  isAvailable: _isNavigationAvailable,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeCaretIndicator extends StatelessWidget {
  final SwipeDirection direction;
  final double progress;
  final bool isAvailable;

  const _SwipeCaretIndicator({
    super.key,
    required this.direction,
    required this.progress,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == SwipeDirection.none || progress <= 0) {
      return const SizedBox.shrink();
    }

    final isBack = direction == SwipeDirection.back;
    final alignment = isBack ? Alignment.centerLeft : Alignment.centerRight;
    final iconData = isBack ? Icons.chevron_left : Icons.chevron_right;

    final isThresholdReached = progress >= 1.0 && isAvailable;
    final clampedProgress = progress.clamp(0.0, 1.0);

    final opacity = isAvailable ? clampedProgress : 0.4;
    final scale = isAvailable ? (0.6 + (clampedProgress * 0.4)) : 0.6;
    final edgeMargin = 12.0 + (clampedProgress * 16.0);

    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    Color bgColor;
    Color iconColor;

    if (!isAvailable) {
      bgColor = Colors.grey.withValues(alpha: 0.3);
      iconColor = Colors.grey.shade600;
    } else if (isThresholdReached) {
      bgColor = colors.accentActive;
      iconColor = Colors.white;
    } else {
      final isDark = theme.brightness == Brightness.dark;
      bgColor = isDark
          ? const Color(0xFF2C2C2C).withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.9);
      iconColor =
          theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87);
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: isBack ? edgeMargin : 0,
          right: isBack ? 0 : edgeMargin,
        ),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(iconData, color: iconColor, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
