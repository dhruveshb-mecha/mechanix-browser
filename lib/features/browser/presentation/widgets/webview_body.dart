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
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
