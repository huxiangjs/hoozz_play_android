///
/// Created on 2026/11/13
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';

class SimpleProgressDialog {
  //
  // Show a non-dismissible dialog with a determinate progress bar.
  // [progress] holds the bar value in the range 0..1 and can be
  // updated from the caller while the transfer is running.
  //
  static void show(
    BuildContext context,
    String text,
    ValueNotifier<double> progress,
  ) {
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
                ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 20,
                    );
                  },
                ),
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
