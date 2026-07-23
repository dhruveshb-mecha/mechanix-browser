import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/home_page_body.dart';

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
                        return tab.controller.value
                            ? Expanded(child: tab.controller.webviewWidget)
                            : tab.controller.loadingWidget;
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
                'Private Browsing',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Pages you view in private tabs won\'t be saved in your history, cookie store, or search history after you close all of your private tabs. Bookmarks and downloads will still be kept.',
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
