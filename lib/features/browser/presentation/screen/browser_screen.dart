import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_notification_toast.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/browser_bottom_bar.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/webview_body.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BrowserBloc>().add(BrowserInitialized());
  }

  double? _baseHeight;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;
    // Track the maximum height seen while no OSK is present.
    if (viewInsets.bottom == 0) {
      if (_baseHeight == null || size.height > _baseHeight!) {
        _baseHeight = size.height;
      }
    }

    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        return Scaffold(
          // Disable default Scaffold resizing to prevent the entire body 
          // from squashing when the software keyboard pops up.
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Use the largest height captured to keep webview stable
                  final targetHeight = _baseHeight ?? constraints.maxHeight;
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: OverflowBox(
                      minHeight: targetHeight,
                      maxHeight: targetHeight,
                      alignment: Alignment.topCenter,
                      child: state.isInitialized
                          ? const BrowserWebviewBody()
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  );
                },
              ),
              // Positioned bottom bar that dynamically floats above 
              // the software keyboard using viewInsets.bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                child: AnimatedSlide(
                  offset: state.isBottomBarVisible
                      ? Offset.zero
                      : const Offset(0, 1),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: const SizedBox(
                    height: 72.0,
                    child: BrowserBottomBar(),
                  ),
                ),
              ),

              const DownloadNotificationOverlay(),
            ],
          ),
        );
      },
    );
  }
}
