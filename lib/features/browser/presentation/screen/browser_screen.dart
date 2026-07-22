import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: state.isInitialized
                        ? const BrowserWebviewBody()
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const BrowserBottomBar(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
