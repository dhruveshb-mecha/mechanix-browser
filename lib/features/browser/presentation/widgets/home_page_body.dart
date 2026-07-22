import 'package:flutter/material.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_home_header.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_home_shortcuts.dart';

class BrowserHomePageBody extends StatefulWidget {
  const BrowserHomePageBody({super.key});

  @override
  State<BrowserHomePageBody> createState() => _BrowserHomePageBodyState();
}

class _BrowserHomePageBodyState extends State<BrowserHomePageBody> {
  bool _isEditMode = false;

  void _exitEditMode() {
    if (_isEditMode) {
      setState(() {
        _isEditMode = false;
      });
    }
  }

  void _enterEditMode() {
    if (!_isEditMode) {
      setState(() {
        _isEditMode = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitEditMode();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _exitEditMode,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrowserHomeHeader(),
              const SizedBox(height: 60),
              BrowserHomeShortcuts(
                isEditMode: _isEditMode,
                onExitEditMode: _exitEditMode,
                onEnterEditMode: _enterEditMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
