import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class FindInPageBar extends StatefulWidget {
  const FindInPageBar({super.key});

  @override
  State<FindInPageBar> createState() => _FindInPageBarState();
}

class _FindInPageBarState extends State<FindInPageBar> {
  late final TextEditingController _findTextController;
  late final FocusNode _findFocusNode;

  @override
  void initState() {
    super.initState();
    _findTextController = TextEditingController();
    _findFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _findTextController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BrowserBloc, BrowserState>(
      buildWhen: (previous, current) =>
          previous.findMatchCountText != current.findMatchCountText,
      builder: (context, state) {
        final bloc = context.read<BrowserBloc>();
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8E8E93),
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          focusNode: _findFocusNode,
                          controller: _findTextController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.findInPage,
                            hintStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),

                          onChanged: (value) {
                            bloc.add(BrowserFindInPageQueryChanged(value));
                          },
                          onSubmitted: (_) {
                            bloc.add(BrowserFindInPageNextRequested());
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Text(
                          state.findMatchCountText,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _FindInPageButton(
                icon: Icons.keyboard_arrow_up,
                onTap: () {
                  bloc.add(BrowserFindInPagePrevRequested());
                },
              ),
              const SizedBox(width: 8),
              _FindInPageButton(
                icon: Icons.keyboard_arrow_down,
                onTap: () {
                  bloc.add(BrowserFindInPageNextRequested());
                },
              ),
              const SizedBox(width: 8),
              _FindInPageButton(
                icon: Icons.close,
                onTap: () {
                  bloc.add(BrowserFindInPageCloseRequested());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FindInPageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FindInPageButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.12),
        hoverColor: Colors.white.withValues(alpha: 0.24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
