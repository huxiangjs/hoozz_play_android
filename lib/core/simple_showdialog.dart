///
/// Created on 2024/05/26
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';

class SimpleShowDialog {
  static void show(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable return key
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 26.0),
                  child: Text(text),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
