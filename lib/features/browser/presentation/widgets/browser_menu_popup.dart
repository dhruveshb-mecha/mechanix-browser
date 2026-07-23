import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';

import 'menu/browser_menu_bottom_bar.dart';
import 'menu/browser_menu_list_section.dart';

class BrowserMenuPopupContent extends StatefulWidget {
  final BrowserBloc bloc;
  final VoidCallback onDismiss;
  final VoidCallback? onFindInPage;

  const BrowserMenuPopupContent({
    super.key,
    required this.bloc,
    required this.onDismiss,
    this.onFindInPage,
  });

  @override
  State<BrowserMenuPopupContent> createState() =>
      _BrowserMenuPopupContentState();
}

class _BrowserMenuPopupContentState extends State<BrowserMenuPopupContent> {
  bool isDesktopSite = false;

  void _toggleDesktopSite(bool newValue) {
    setState(() {
      isDesktopSite = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return BlocBuilder<BrowserBloc, BrowserState>(
      bloc: widget.bloc,
      builder: (context, state) {
        return Container(
          width: 346,
          height: 395,
          decoration: BoxDecoration(
            color: colors.panelBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.panelBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.popupBarrierColor.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrowserMenuListSection(
                bloc: widget.bloc,
                state: state,
                isDesktopSite: isDesktopSite,
                onToggleDesktopSite: _toggleDesktopSite,
                onDismiss: widget.onDismiss,
              ),
              Divider(color: colors.panelBorder, height: 1, thickness: 1),
              BrowserMenuBottomBar(
                bloc: widget.bloc,
                state: state,
                onDismiss: widget.onDismiss,
                onFindInPage: widget.onFindInPage,
              ),
            ],
          ),
        );
      },
    );
  }
}
