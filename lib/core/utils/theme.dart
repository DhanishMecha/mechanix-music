import 'package:flutter/material.dart';
import 'package:mechanix_music/core/utils/colors.dart';

class AppTheme {
  static final dark = ThemeData.dark(useMaterial3: true).copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    scaffoldBackgroundColor: Colors.black,
    textTheme: ThemeData.dark(
      useMaterial3: true,
    ).textTheme.apply(fontFamily: "Sora"),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
    ),
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(4),
      thickness: WidgetStatePropertyAll(4),
      thumbColor: WidgetStatePropertyAll(MusicColors.timeLabelColor),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
  );

  static final light = ThemeData.light(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: ThemeData.light(
      useMaterial3: true,
    ).textTheme.apply(fontFamily: "Sora"),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
    ),
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(4),
      thickness: WidgetStatePropertyAll(4),
      thumbColor: WidgetStatePropertyAll(MusicColors.timeLabelColor),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
  );
}
