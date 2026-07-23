import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/home_page_body.dart';

class BrowserWebviewBody extends StatelessWidget {
  const BrowserWebviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowserBloc, BrowserState>(
      buildWhen: (previous, current) =>
          previous.tabs != current.tabs ||
          previous.activeTabIndex != current.activeTabIndex,
      builder: (context, state) {
        if (state.tabs.isEmpty) {
          return const SizedBox.shrink();
        }
        return IndexedStack(
          index: state.activeTabIndex,
          children: state.tabs.map((tab) {
            return Stack(
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
