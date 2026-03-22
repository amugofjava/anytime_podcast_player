// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _headlineFontFamily = 'Manrope';
const String _bodyFontFamily = 'Inter';

final ThemeData _lightTheme = _buildTheme(
  colorScheme: _lightColorScheme,
  brightness: Brightness.light,
);
final ThemeData _darkTheme = _buildTheme(
  colorScheme: _darkColorScheme,
  brightness: Brightness.dark,
);

const ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff163428),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xff2d4b3e),
  onPrimaryContainer: Color(0xffd8ecdf),
  primaryFixed: Color(0xffc8ead8),
  primaryFixedDim: Color(0xffadcebd),
  onPrimaryFixed: Color(0xff012116),
  onPrimaryFixedVariant: Color(0xff2f4d40),
  secondary: Color(0xff506259),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffd0e4d9),
  onSecondaryContainer: Color(0xff23352d),
  secondaryFixed: Color(0xffd3e7dc),
  secondaryFixedDim: Color(0xffb7cbc0),
  onSecondaryFixed: Color(0xff0e1f18),
  onSecondaryFixedVariant: Color(0xff394b42),
  tertiary: Color(0xff24322b),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xff3a4840),
  onTertiaryContainer: Color(0xffd7e6dc),
  tertiaryFixed: Color(0xffd7e6dc),
  tertiaryFixedDim: Color(0xffbbcac0),
  onTertiaryFixed: Color(0xff111e18),
  onTertiaryFixedVariant: Color(0xff3c4a42),
  error: Color(0xffba1a1a),
  onError: Color(0xffffffff),
  errorContainer: Color(0xffffdad6),
  onErrorContainer: Color(0xff93000a),
  surface: Color(0xfff7faf6),
  onSurface: Color(0xff181c1a),
  onSurfaceVariant: Color(0xff424844),
  outline: Color(0xff727974),
  outlineVariant: Color(0xffc1c8c3),
  shadow: Color(0xff0e1713),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xff2d312f),
  onInverseSurface: Color(0xffeef2ed),
  inversePrimary: Color(0xffadcebd),
  surfaceTint: Color(0xff466557),
  surfaceDim: Color(0xffd8dbd7),
  surfaceBright: Color(0xfff7faf6),
  surfaceContainerLowest: Color(0xffffffff),
  surfaceContainerLow: Color(0xfff1f4f0),
  surfaceContainer: Color(0xffecefeb),
  surfaceContainerHigh: Color(0xffe6e9e5),
  surfaceContainerHighest: Color(0xffe0e3df),
);

const ColorScheme _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffadcebd),
  onPrimary: Color(0xff0f281f),
  primaryContainer: Color(0xff213a2f),
  onPrimaryContainer: Color(0xffd8ecdf),
  primaryFixed: Color(0xffc8ead8),
  primaryFixedDim: Color(0xffadcebd),
  onPrimaryFixed: Color(0xff012116),
  onPrimaryFixedVariant: Color(0xff2f4d40),
  secondary: Color(0xffb7cbc0),
  onSecondary: Color(0xff22342c),
  secondaryContainer: Color(0xff394b42),
  onSecondaryContainer: Color(0xffd8ecdf),
  secondaryFixed: Color(0xffd3e7dc),
  secondaryFixedDim: Color(0xffb7cbc0),
  onSecondaryFixed: Color(0xff0e1f18),
  onSecondaryFixedVariant: Color(0xff394b42),
  tertiary: Color(0xffbbcac0),
  onTertiary: Color(0xff1f2d26),
  tertiaryContainer: Color(0xff314038),
  onTertiaryContainer: Color(0xffd7e6dc),
  tertiaryFixed: Color(0xffd7e6dc),
  tertiaryFixedDim: Color(0xffbbcac0),
  onTertiaryFixed: Color(0xff111e18),
  onTertiaryFixedVariant: Color(0xff3c4a42),
  error: Color(0xffffb4ab),
  onError: Color(0xff690005),
  errorContainer: Color(0xff93000a),
  onErrorContainer: Color(0xffffdad6),
  surface: Color(0xff111715),
  onSurface: Color(0xffe0e3df),
  onSurfaceVariant: Color(0xffc1c8c3),
  outline: Color(0xff8b938d),
  outlineVariant: Color(0xff424844),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xffe0e3df),
  onInverseSurface: Color(0xff2a2f2c),
  inversePrimary: Color(0xff305043),
  surfaceTint: Color(0xffadcebd),
  surfaceDim: Color(0xff111715),
  surfaceBright: Color(0xff373d3a),
  surfaceContainerLowest: Color(0xff0c120f),
  surfaceContainerLow: Color(0xff171d1a),
  surfaceContainer: Color(0xff1b211e),
  surfaceContainerHigh: Color(0xff262c29),
  surfaceContainerHighest: Color(0xff303633),
);

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
  );
  final textTheme = _buildTextTheme(base.textTheme, brightness, colorScheme);
  final overlayStyle = _systemOverlayStyle(colorScheme, brightness);
  final dividerColor = colorScheme.outlineVariant.withValues(alpha: 0.22);

  return base.copyWith(
    colorScheme: colorScheme,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    cardColor: colorScheme.surfaceContainerLowest,
    dividerColor: dividerColor,
    primaryColor: colorScheme.primary,
    secondaryHeaderColor: colorScheme.surfaceContainerLow,
    highlightColor: colorScheme.surfaceContainerHigh,
    splashColor: colorScheme.primary.withValues(alpha: 0.12),
    hintColor: colorScheme.outline,
    disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
    unselectedWidgetColor: colorScheme.onSurfaceVariant,
    iconTheme: IconThemeData(color: colorScheme.primary),
    primaryIconTheme: IconThemeData(color: colorScheme.primary),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      centerTitle: false,
      systemOverlayStyle: overlayStyle,
      titleTextStyle: textTheme.headlineSmall,
      toolbarTextStyle: textTheme.bodyMedium,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: colorScheme.surface.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall!.copyWith(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 0.2,
        );
      }),
      indicatorColor: colorScheme.secondaryContainer,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shadowColor: colorScheme.primary.withValues(alpha: brightness == Brightness.light ? 0.08 : 0.18),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primary,
      secondarySelectedColor: colorScheme.primary,
      disabledColor: colorScheme.surfaceContainer,
      side: BorderSide.none,
      labelStyle: textTheme.labelLarge!.copyWith(color: colorScheme.primary),
      secondaryLabelStyle: textTheme.labelLarge!.copyWith(color: colorScheme.onPrimary),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      showCheckmark: false,
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: colorScheme.surface.withValues(alpha: 0.96),
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: colorScheme.onInverseSurface),
      actionTextColor: colorScheme.primaryFixedDim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      hintStyle: textTheme.bodyLarge!.copyWith(color: colorScheme.outline),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.45), width: 1.5),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.primary,
      textColor: colorScheme.onSurface,
      subtitleTextStyle: textTheme.bodySmall!.copyWith(color: colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      trackHeight: 6,
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      secondaryActiveTrackColor: colorScheme.primaryContainer,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colorScheme.primaryContainer,
      valueIndicatorTextStyle: textTheme.labelMedium!.copyWith(color: colorScheme.onPrimary),
      trackShape: const RoundedRectSliderTrackShape(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      circularTrackColor: colorScheme.surfaceContainerHigh,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      linearMinHeight: 6,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      textStyle: textTheme.bodyMedium,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outlineVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHighest;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        hoverColor: colorScheme.surfaceContainer,
        highlightColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primaryFixedDim.withValues(alpha: 0.5),
      selectionHandleColor: colorScheme.primary,
    ),
  );
}

TextTheme _buildTextTheme(
  TextTheme base,
  Brightness brightness,
  ColorScheme colorScheme,
) {
  final body = base.apply(
    fontFamily: _bodyFontFamily,
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  TextStyle headline(TextStyle? style, {FontWeight weight = FontWeight.w700, double? letterSpacing}) {
    return style!.copyWith(
      fontFamily: _headlineFontFamily,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: colorScheme.onSurface,
    );
  }

  return body.copyWith(
    displayLarge: headline(body.displayLarge, weight: FontWeight.w800, letterSpacing: -1.6),
    displayMedium: headline(body.displayMedium, weight: FontWeight.w800, letterSpacing: -1.2),
    displaySmall: headline(body.displaySmall, weight: FontWeight.w800, letterSpacing: -0.9),
    headlineLarge: headline(body.headlineLarge, weight: FontWeight.w800, letterSpacing: -0.8),
    headlineMedium: headline(body.headlineMedium, weight: FontWeight.w700, letterSpacing: -0.6),
    headlineSmall: headline(body.headlineSmall, weight: FontWeight.w700, letterSpacing: -0.4),
    titleLarge: headline(body.titleLarge, weight: FontWeight.w800, letterSpacing: -0.4),
    titleMedium: headline(body.titleMedium, weight: FontWeight.w700, letterSpacing: -0.2),
    titleSmall: headline(body.titleSmall, weight: FontWeight.w700, letterSpacing: -0.1),
    bodyLarge: body.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    bodyMedium: body.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    bodySmall: body.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
    ),
    labelLarge: body.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: colorScheme.onSurface,
    ),
    labelMedium: body.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: colorScheme.onSurfaceVariant,
    ),
    labelSmall: body.labelSmall?.copyWith(
      fontWeight: brightness == Brightness.light ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: 0.4,
      color: colorScheme.onSurfaceVariant,
    ),
  );
}

SystemUiOverlayStyle _systemOverlayStyle(
  ColorScheme colorScheme,
  Brightness brightness,
) {
  final iconBrightness = brightness == Brightness.light ? Brightness.dark : Brightness.light;

  return SystemUiOverlayStyle(
    systemNavigationBarColor: colorScheme.surface,
    systemNavigationBarIconBrightness: iconBrightness,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: brightness == Brightness.light ? Brightness.light : Brightness.dark,
  );
}

class Themes {
  final ThemeData themeData;

  Themes({required this.themeData});

  factory Themes.lightTheme() {
    return Themes(themeData: _lightTheme);
  }

  factory Themes.darkTheme() {
    return Themes(themeData: _darkTheme);
  }
}
