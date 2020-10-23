// Copyright 2020 Ben Hills. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final ThemeData _lightTheme = _buildLightTheme();
final ThemeData _darkTheme = _buildDarktheme();

ThemeData _buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    brightness: Brightness.light,
    primaryColor: Color(0xffff9800),
    primaryColorBrightness: Brightness.light,
    primaryColorLight: Color(0xffffe0b2),
    primaryColorDark: Color(0xfff57c00),
    accentColor: Color(0xffff9800),
    accentColorBrightness: Brightness.light,
    canvasColor: Color(0xfffafafa),
    scaffoldBackgroundColor: Color(0xfffafafa),
    bottomAppBarColor: Color(0xffffffff),
    cardColor: Color(0xffffffff),
    dividerColor: Color(0x1f000000),
    highlightColor: Color(0x66bcbcbc),
    splashColor: Color(0x66c8c8c8),
    selectedRowColor: Color(0xfff5f5f5),
    unselectedWidgetColor: Color(0x8a000000),
    disabledColor: Color(0x61000000),
    buttonColor: Color(0xffe0e0e0),
    toggleableActiveColor: Color(0xfffb8c00),
    secondaryHeaderColor: Color(0xfffff3e0),
    textSelectionColor: Color(0xffffcc80),
    cursorColor: Color(0xff4285f4),
    textSelectionHandleColor: Color(0xffffb74d),
    backgroundColor: Colors.white,
    dialogBackgroundColor: Color(0xffffffff),
    indicatorColor: Colors.grey[800],
    hintColor: Color(0x8a000000),
    errorColor: Color(0xffd32f2f),
    primaryIconTheme: IconThemeData(color: Colors.grey[800]),
    iconTheme: IconThemeData(color: Colors.orange),
  );
}

ThemeData _buildDarktheme() {
  final base = ThemeData.dark();

  return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: Color(0xff212121),
      primaryColorBrightness: Brightness.dark,
      primaryColorLight: Color(0xff9e9e9e),
      primaryColorDark: Color(0xff000000),
      accentColor: Color(0xffffffff),
      accentColorBrightness: Brightness.light,
      canvasColor: Color(0xff303030),
      scaffoldBackgroundColor: Color(0xff303030),
      bottomAppBarColor: Color(0xff424242),
      cardColor: Color(0xff424242),
      dividerColor: Color(0x1fffffff),
      highlightColor: Color(0x40cccccc),
      splashColor: Color(0x40cccccc),
      selectedRowColor: Color(0xfff5f5f5),
      unselectedWidgetColor: Color(0xb3ffffff),
      disabledColor: Color(0x62ffffff),
      buttonColor: Colors.white,
      toggleableActiveColor: Color(0xff64ffda),
      secondaryHeaderColor: Color(0xff616161),
      textSelectionColor: Color(0xff64ffda),
      cursorColor: Color(0xff4285f4),
      textSelectionHandleColor: Color(0xff1de9b6),
      backgroundColor: Color(0xff121212),
      // backgroundColor: Color(0xff616161),
      dialogBackgroundColor: Color(0xff424242),
      indicatorColor: Colors.white,
      hintColor: Color(0x80ffffff),
      errorColor: Color(0xffd32f2f),
      appBarTheme: base.appBarTheme.copyWith(
        color: Color(0xff424242),
      ));
}

class Themes {
  final ThemeData themeData;

  Themes({@required this.themeData});

  factory Themes.lightTheme() {
    return Themes(themeData: _lightTheme);
  }

  factory Themes.darkTheme() {
    return Themes(themeData: _darkTheme);
  }
}
