///
/// Created on 2023/09/03
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MaterialColor mainFillColor = Colors.amber;
const Color mainTextColor = Colors.black;
const Color subTextColor = Color.fromARGB(0xff, 0x6f, 0x6f, 0x6f);
const String mainFontFamily = 'YouSheBiaoTiHei';
const String subFontFamily = 'Droid Sans Fallback';
const Color mainBackgroundColor = Color.fromARGB(0xef, 0xff, 0xff, 0xff);

ThemeData appTheme() {
  return ThemeData(
    primarySwatch: mainFillColor,
    fontFamily: mainFontFamily,
    /* Background color */
    // scaffoldBackgroundColor: mainBackgroundColor,
    /* Text color */
    textTheme: const TextTheme(
      // titleLarge: TextStyle(fontSize: 32, color: mainTextColor),
      // titleMedium: TextStyle(fontSize: 24, color: mainTextColor),
      // titleSmall: TextStyle(fontSize: 15, color: mainTextColor),
      // bodyLarge: TextStyle(fontSize: 32, color: mainTextColor),
      // bodyMedium: TextStyle(fontSize: 24, color: mainTextColor),
      // bodySmall: TextStyle(fontSize: 15, color: mainTextColor),
    ),
    appBarTheme: const AppBarTheme(
      toolbarHeight: 80,
      // systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: mainFillColor),
      // elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontFamily: subFontFamily,
        fontWeight: FontWeight.bold,
      ),
      color: mainFillColor,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    sliderTheme: const SliderThemeData(
      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
      valueIndicatorTextStyle: TextStyle(color: Colors.white, fontSize: 12),
    ),
    listTileTheme: const ListTileThemeData(textColor: mainTextColor),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.all(mainFillColor),
      visualDensity: VisualDensity.compact,
    ),
    iconTheme: const IconThemeData(size: 30),
  );
}
