import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color searchBarBackground;
  final Color searchBarBorder;
  final Color searchBarHint;
  final Color searchBarText;
  final Color textSecondary;
  final Color textTertiary;
  final Color inactiveGrey;
  final Color dividerColor;
  final Color panelBackground;
  final Color panelBorder;
  final Color dragHandle;
  final Color closeButtonBackground;
  final Color shortcutBorder;
  final Color shortcutForeground;
  final Color shortcutHoverBorder;
  final Color shortcutHoverBackground;
  final Color shortcutHoverForeground;
  final Color popupBottomBackground;
  final Color popupBottomButtonBackground;
  final Color popupBarrierColor;
  final Color accentActive;

  const AppColorsExtension({
    required this.searchBarBackground,
    required this.searchBarBorder,
    required this.searchBarHint,
    required this.searchBarText,
    required this.textSecondary,
    required this.textTertiary,
    required this.inactiveGrey,
    required this.dividerColor,
    required this.panelBackground,
    required this.panelBorder,
    required this.dragHandle,
    required this.closeButtonBackground,
    required this.shortcutBorder,
    required this.shortcutForeground,
    required this.shortcutHoverBorder,
    required this.shortcutHoverBackground,
    required this.shortcutHoverForeground,
    required this.popupBottomBackground,
    required this.popupBottomButtonBackground,
    required this.popupBarrierColor,
    required this.accentActive,
  });

  @override
  AppColorsExtension copyWith({
    Color? searchBarBackground,
    Color? searchBarBorder,
    Color? searchBarHint,
    Color? searchBarText,
    Color? textSecondary,
    Color? textTertiary,
    Color? inactiveGrey,
    Color? dividerColor,
    Color? panelBackground,
    Color? panelBorder,
    Color? dragHandle,
    Color? closeButtonBackground,
    Color? shortcutBorder,
    Color? shortcutForeground,
    Color? shortcutHoverBorder,
    Color? shortcutHoverBackground,
    Color? shortcutHoverForeground,
    Color? popupBottomBackground,
    Color? popupBottomButtonBackground,
    Color? popupBarrierColor,
    Color? accentActive,
  }) {
    return AppColorsExtension(
      searchBarBackground: searchBarBackground ?? this.searchBarBackground,
      searchBarBorder: searchBarBorder ?? this.searchBarBorder,
      searchBarHint: searchBarHint ?? this.searchBarHint,
      searchBarText: searchBarText ?? this.searchBarText,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      inactiveGrey: inactiveGrey ?? this.inactiveGrey,
      dividerColor: dividerColor ?? this.dividerColor,
      panelBackground: panelBackground ?? this.panelBackground,
      panelBorder: panelBorder ?? this.panelBorder,
      dragHandle: dragHandle ?? this.dragHandle,
      closeButtonBackground:
          closeButtonBackground ?? this.closeButtonBackground,
      shortcutBorder: shortcutBorder ?? this.shortcutBorder,
      shortcutForeground: shortcutForeground ?? this.shortcutForeground,
      shortcutHoverBorder: shortcutHoverBorder ?? this.shortcutHoverBorder,
      shortcutHoverBackground:
          shortcutHoverBackground ?? this.shortcutHoverBackground,
      shortcutHoverForeground:
          shortcutHoverForeground ?? this.shortcutHoverForeground,
      popupBottomBackground:
          popupBottomBackground ?? this.popupBottomBackground,
      popupBottomButtonBackground:
          popupBottomButtonBackground ?? this.popupBottomButtonBackground,
      popupBarrierColor: popupBarrierColor ?? this.popupBarrierColor,
      accentActive: accentActive ?? this.accentActive,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      searchBarBackground:
          Color.lerp(searchBarBackground, other.searchBarBackground, t)!,
      searchBarBorder: Color.lerp(searchBarBorder, other.searchBarBorder, t)!,
      searchBarHint: Color.lerp(searchBarHint, other.searchBarHint, t)!,
      searchBarText: Color.lerp(searchBarText, other.searchBarText, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      inactiveGrey: Color.lerp(inactiveGrey, other.inactiveGrey, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      dragHandle: Color.lerp(dragHandle, other.dragHandle, t)!,
      closeButtonBackground:
          Color.lerp(closeButtonBackground, other.closeButtonBackground, t)!,
      shortcutBorder: Color.lerp(shortcutBorder, other.shortcutBorder, t)!,
      shortcutForeground:
          Color.lerp(shortcutForeground, other.shortcutForeground, t)!,
      shortcutHoverBorder:
          Color.lerp(shortcutHoverBorder, other.shortcutHoverBorder, t)!,
      shortcutHoverBackground: Color.lerp(
          shortcutHoverBackground, other.shortcutHoverBackground, t)!,
      shortcutHoverForeground: Color.lerp(
          shortcutHoverForeground, other.shortcutHoverForeground, t)!,
      popupBottomBackground:
          Color.lerp(popupBottomBackground, other.popupBottomBackground, t)!,
      popupBottomButtonBackground: Color.lerp(
          popupBottomButtonBackground, other.popupBottomButtonBackground, t)!,
      popupBarrierColor:
          Color.lerp(popupBarrierColor, other.popupBarrierColor, t)!,
      accentActive: Color.lerp(accentActive, other.accentActive, t)!,
    );
  }

  static const dark = AppColorsExtension(
    searchBarBackground: Color(0xFF1C1C1E),
    searchBarBorder: Colors.white10,
    searchBarHint: Color(0xFF8E8E93),
    searchBarText: Colors.white,
    textSecondary: Colors.white70,
    textTertiary: Colors.white30,
    inactiveGrey: Color(0xFF8E8E93),
    dividerColor: Colors.white12,
    panelBackground: Color(0xFF1E1E1E),
    panelBorder: Colors.white24,
    dragHandle: Colors.white24,
    closeButtonBackground: Colors.white12,
    shortcutBorder: Color(0xFF333333),
    shortcutForeground: Color(0xFF555555),
    shortcutHoverBorder: Colors.white54,
    shortcutHoverBackground: Colors.white10,
    shortcutHoverForeground: Colors.white,
    popupBottomBackground: Color(0xFF151515),
    popupBottomButtonBackground: Color(0xFF2C2C2E),
    popupBarrierColor: Colors.black26,
    accentActive: Colors.blueAccent,
  );
}

class AppTheme {
  static const String fontFamily = 'Sora';

  static final dark = ThemeData.dark(useMaterial3: true).copyWith(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.white70,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white, size: 20),
      actionsIconTheme: IconThemeData(color: Colors.white, size: 20),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF151515),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white10,
      space: 16,
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF8E8E93),
      textColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      visualDensity: VisualDensity(vertical: -1),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      side: const BorderSide(
        color: Colors.white30,
        width: 1.5,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: Colors.white30,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white38,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: Color(0xFF8E8E93),
      ),
    ),
    extensions: [
      AppColorsExtension.dark,
    ],
  );

  static final light = ThemeData.light(useMaterial3: true).copyWith(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
    ),
  );
}
