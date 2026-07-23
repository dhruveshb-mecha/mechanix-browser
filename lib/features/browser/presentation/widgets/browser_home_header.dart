import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BrowserHomeHeader extends StatelessWidget {
  const BrowserHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BrowserBloc, BrowserState>(
      builder: (context, state) {
        final isPrivate = state.mode == BrowserMode.private;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isPrivate
                ? Image.asset(AppImages.incognitoImage, width: 42, height: 42)
                : Image.asset(AppImages.logo, width: 42, height: 42),
            const SizedBox(width: 14),
            Text(
              isPrivate ? '${l10n.appTitle} (Private)' : l10n.appTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}
