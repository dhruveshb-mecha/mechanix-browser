import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class BrowserHomeHeader extends StatelessWidget {
  const BrowserHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AppImages.logo, width: 42, height: 42),
        const SizedBox(width: 14),
        Text(
          l10n.appTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
