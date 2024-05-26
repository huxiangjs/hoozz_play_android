///
/// Created on 2024/05/26
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';

class SimpleSnackBar {
  static void show(BuildContext context, String str, Color bgColor) {
    SnackBar snackBar = SnackBar(
        content: Text(
          str,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: mainFontFamily,
          ),
        ),
        backgroundColor: bgColor);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
